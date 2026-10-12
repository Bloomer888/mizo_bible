import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/user_database.dart';
import 'reading_plan.dart';

const _uuid = Uuid();

class ReadingPlanState {
  final String planId;
  final ReadingPlan plan;
  final Set<int> completedDays;

  /// The lowest day number not yet marked complete -- null once every
  /// day is done. "Self-paced" means this is the only notion of
  /// "where you are," never a calendar date, so marking several days
  /// complete in one sitting after a few busy days just advances this
  /// normally instead of needing separate catch-up handling.
  final int? currentDay;

  const ReadingPlanState({
    required this.planId,
    required this.plan,
    required this.completedDays,
    required this.currentDay,
  });

  bool get isComplete => currentDay == null;
}

Set<int> _parseCompletedDays(String csv) {
  if (csv.isEmpty) return {};
  return csv.split(',').map(int.parse).toSet();
}

String _encodeCompletedDays(Set<int> days) {
  final sorted = days.toList()..sort();
  return sorted.join(',');
}

/// The most recently started plan, if any. Reads back whichever
/// progress row was touched most recently, same "most recent wins"
/// pattern as loadMostRecentReadingProgress -- there's only ever one
/// plan available right now (see reading_plan.dart), but this doesn't
/// assume that stays true.
Future<ReadingPlanState?> loadActivePlanProgress(UserDatabase db) async {
  final rows = await db.customSelect(
    'select plan_id, completed_days_csv from reading_plan_progress where deleted = 0 order by rowid desc limit 1',
    readsFrom: {db.readingPlanProgress},
  ).get();
  if (rows.isEmpty) return null;

  final row = rows.single;
  final planId = row.read<String>('plan_id');
  final plan = findReadingPlan(planId);
  // The plan this progress row points at no longer exists in the app
  // (should only happen if a plan were ever removed in a future
  // update) -- degrade to "nothing active" rather than crash Home.
  if (plan == null) return null;

  final completedDays = _parseCompletedDays(row.read<String>('completed_days_csv'));
  int? currentDay;
  for (var day = 1; day <= plan.totalDays; day++) {
    if (!completedDays.contains(day)) {
      currentDay = day;
      break;
    }
  }

  return ReadingPlanState(planId: planId, plan: plan, completedDays: completedDays, currentDay: currentDay);
}

Future<void> startReadingPlan(UserDatabase db, String planId) async {
  await db.into(db.readingPlanProgress).insert(
        ReadingPlanProgressCompanion.insert(id: _uuid.v4(), planId: planId),
      );
}

/// Marks [day] complete on [planId]'s progress, creating the progress
/// row first if somehow called before [startReadingPlan]. Delete-and-
/// reinsert rather than an in-place update -- same reason as
/// saveReadingProgress in reading_progress_repository.dart: an
/// in-place update leaves the row's rowid untouched, which is exactly
/// backwards for loadActivePlanProgress's "most recently touched"
/// ordering. startedAt carries over from the existing row so it still
/// means "when this plan began," not "last touched."
Future<void> markReadingPlanDayComplete(UserDatabase db, {required String planId, required int day}) async {
  final existing = await (db.select(db.readingPlanProgress)
        ..where((p) => p.planId.equals(planId) & p.deleted.equals(false))
        ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])
        ..limit(1))
      .getSingleOrNull();

  final completedDays = existing == null ? <int>{} : _parseCompletedDays(existing.completedDaysCsv);
  completedDays.add(day);
  final csv = _encodeCompletedDays(completedDays);

  await db.transaction(() async {
    if (existing != null) {
      await (db.delete(db.readingPlanProgress)..where((p) => p.id.equals(existing.id))).go();
      await db.into(db.readingPlanProgress).insert(
            ReadingPlanProgressCompanion.insert(
              id: _uuid.v4(),
              planId: planId,
              startedAt: Value(existing.startedAt),
              completedDaysCsv: Value(csv),
            ),
          );
    } else {
      await db.into(db.readingPlanProgress).insert(
            ReadingPlanProgressCompanion.insert(id: _uuid.v4(), planId: planId, completedDaysCsv: Value(csv)),
          );
    }
  });
}
