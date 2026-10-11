import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../home/data/verse_of_the_day.dart';

/// Two separate standing notifications for Premium members, deliberately
/// distinct from each other:
///
/// - The daily quote: fires every day at a fixed hour, generic text,
///   not the actual verse -- Android re-fires the same stored title/
///   body every day at this hour without re-running any app code
///   (`matchDateTimeComponents: DateTimeComponents.time`), so baking
///   today's verse text in would just freeze that one day's verse
///   forever.
/// - The verse-changed notification: fires once, right when the Verse
///   of the Day actually rotates (every 60 hours -- see
///   verseRotationPeriod in verse_of_the_day.dart), re-scheduled fresh
///   on every app open/resume rather than a native repeat, since 60
///   hours doesn't land on a fixed calendar pattern
///   matchDateTimeComponents can express.
///
/// The real verse only ever renders from `loadVerseOfTheDay`, fresh,
/// when the app is actually open -- both notifications are just the
/// nudge to go look, never the content itself.
const _dailyQuoteChannelId = 'daily_quote';
const _dailyQuoteChannelName = 'Daily Quote';
const _dailyQuoteNotificationId = 7210;
const _dailyQuoteHour = 8; // 8:00 AM local -- a standard devotional-reminder slot.

const _verseChangedChannelId = 'verse_of_the_day_changed';
const _verseChangedChannelName = 'Verse of the Day Changed';
const _verseChangedNotificationId = 7211;

final _plugin = FlutterLocalNotificationsPlugin();
bool _initialized = false;

/// Idempotent, so every call site (app start, every Premium-state
/// change, every resume) can call it without tracking whether some
/// earlier call already did.
Future<void> _ensureInitialized() async {
  if (_initialized) return;
  tz.initializeTimeZones();
  try {
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));
  } catch (_) {
    // Falls back to the timezone package's own default (UTC) -- the
    // reminder firing at the wrong absolute hour is a minor
    // inconvenience, not worth failing notification setup over.
  }
  await _plugin.initialize(
    settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
  );
  _initialized = true;
}

/// Android 13+ only; earlier versions grant notification permission at
/// install time and this resolves to null, which the caller treats as
/// granted. Must be awaited before the first schedule call -- unlike
/// most runtime permissions, Android only lets an app prompt for this
/// once per install, so this can't be fire-and-forget.
Future<bool> requestNotificationPermission() async {
  await _ensureInitialized();
  final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  final granted = await androidPlugin?.requestNotificationsPermission();
  return granted ?? true;
}

Future<void> scheduleDailyQuoteNotification() async {
  await _ensureInitialized();
  await _plugin.zonedSchedule(
    id: _dailyQuoteNotificationId,
    title: 'Daily Quote',
    body: "Today's quote is ready. Tap to read it.",
    scheduledDate: _nextInstanceOfHour(_dailyQuoteHour),
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        _dailyQuoteChannelId,
        _dailyQuoteChannelName,
        channelDescription: 'A daily reminder to read today\'s quote',
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

/// One-shot, not repeating -- scheduled for the exact instant
/// [nextRotationAfter] says the current Verse of the Day will next
/// change. Call again on every app open/resume (see app.dart) so an
/// active user always has a fresh, correctly-timed notification queued
/// for the *next* rotation; replaces whatever was scheduled before
/// under the same id, so calling this repeatedly never stacks up
/// duplicates.
Future<void> scheduleVerseChangeNotification() async {
  await _ensureInitialized();
  final next = tz.TZDateTime.from(nextRotationAfter(DateTime.now()), tz.local);
  await _plugin.zonedSchedule(
    id: _verseChangedNotificationId,
    title: 'New Verse of the Day',
    body: 'Your Verse of the Day just changed. Tap to read it.',
    scheduledDate: next,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        _verseChangedChannelId,
        _verseChangedChannelName,
        channelDescription: 'Lets you know the moment the Verse of the Day changes',
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );
}

/// Safe to call even if nothing was ever scheduled -- `cancel` on an
/// unknown id is a no-op, not an error.
Future<void> cancelAllDailyVerseNotifications() async {
  await _ensureInitialized();
  await _plugin.cancel(id: _dailyQuoteNotificationId);
  await _plugin.cancel(id: _verseChangedNotificationId);
}

tz.TZDateTime _nextInstanceOfHour(int hour) {
  final now = tz.TZDateTime.now(tz.local);
  var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
  if (!scheduled.isAfter(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}
