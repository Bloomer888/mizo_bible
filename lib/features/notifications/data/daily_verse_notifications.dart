import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// A single standing daily reminder for Premium members -- deliberately
/// generic text, not the actual verse. `matchDateTimeComponents:
/// DateTimeComponents.time` makes Android re-fire the same stored
/// title/body every day at this hour without re-running any app code,
/// so baking today's verse text in would just freeze that one day's
/// verse forever. The real verse only ever renders from
/// `loadVerseOfTheDay`, fresh, when the app is actually open -- this
/// notification is just the nudge to go look.
const _channelId = 'daily_verse';
const _channelName = 'Daily Verse';
const _notificationId = 7210;
const _hour = 8; // 8:00 AM local -- a standard devotional-reminder slot.

final _plugin = FlutterLocalNotificationsPlugin();
bool _initialized = false;

/// Idempotent, so every call site (app start, every Premium-state
/// change) can call it without tracking whether some earlier call
/// already did.
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

Future<void> scheduleDailyVerseNotification() async {
  await _ensureInitialized();
  await _plugin.zonedSchedule(
    id: _notificationId,
    title: 'Verse of the Day',
    body: 'Your daily verse is ready. Tap to read it.',
    scheduledDate: _nextInstanceOfHour(_hour),
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'A daily reminder with your Verse of the Day',
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

/// Safe to call even if nothing was ever scheduled -- `cancel` on an
/// unknown id is a no-op, not an error.
Future<void> cancelDailyVerseNotification() async {
  await _ensureInitialized();
  await _plugin.cancel(id: _notificationId);
}

tz.TZDateTime _nextInstanceOfHour(int hour) {
  final now = tz.TZDateTime.now(tz.local);
  var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
  if (!scheduled.isAfter(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}
