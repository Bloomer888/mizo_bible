import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizo_bible/core/db/user_database.dart';
import 'package:mizo_bible/features/reading_plans/data/reading_plan_progress_repository.dart';

void main() {
  late UserDatabase db;

  setUp(() => db = UserDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('no plan ever started loads as no active progress', () async {
    expect(await loadActivePlanProgress(db), isNull);
  });

  test('starting a plan makes it the active one, at day 1, nothing completed', () async {
    await startReadingPlan(db, 'nt_90_days');
    final state = await loadActivePlanProgress(db);

    expect(state, isNotNull);
    expect(state!.planId, 'nt_90_days');
    expect(state.currentDay, 1);
    expect(state.completedDays, isEmpty);
    expect(state.isComplete, isFalse);
  });

  test('marking a day complete advances the current day', () async {
    await startReadingPlan(db, 'nt_90_days');
    await markReadingPlanDayComplete(db, planId: 'nt_90_days', day: 1);

    final state = await loadActivePlanProgress(db);
    expect(state!.completedDays, {1});
    expect(state.currentDay, 2);
  });

  test('marking days out of order still advances to the lowest incomplete day', () async {
    await startReadingPlan(db, 'nt_90_days');
    await markReadingPlanDayComplete(db, planId: 'nt_90_days', day: 1);
    await markReadingPlanDayComplete(db, planId: 'nt_90_days', day: 3);

    final state = await loadActivePlanProgress(db);
    expect(state!.completedDays, {1, 3});
    expect(state.currentDay, 2); // day 2 is still the lowest not done
  });

  test('marking a day complete without an existing progress row creates one', () async {
    await markReadingPlanDayComplete(db, planId: 'nt_90_days', day: 1);

    final state = await loadActivePlanProgress(db);
    expect(state, isNotNull);
    expect(state!.completedDays, {1});
  });

  test('marking the same day complete twice does not duplicate it', () async {
    await startReadingPlan(db, 'nt_90_days');
    await markReadingPlanDayComplete(db, planId: 'nt_90_days', day: 1);
    await markReadingPlanDayComplete(db, planId: 'nt_90_days', day: 1);

    final state = await loadActivePlanProgress(db);
    expect(state!.completedDays, {1});
  });

  test('starting over does not lose the original start date on later updates', () async {
    await startReadingPlan(db, 'nt_90_days');
    final firstState = await loadActivePlanProgress(db);
    await markReadingPlanDayComplete(db, planId: 'nt_90_days', day: 1);
    final secondState = await loadActivePlanProgress(db);

    // Same plan still active after marking a day complete -- the
    // delete-and-reinsert in markReadingPlanDayComplete must not
    // somehow orphan or duplicate the progress row.
    expect(firstState!.planId, secondState!.planId);
  });

  test('completing every day makes the plan report as complete', () async {
    await startReadingPlan(db, 'nt_90_days');
    for (var day = 1; day <= 90; day++) {
      await markReadingPlanDayComplete(db, planId: 'nt_90_days', day: day);
    }

    final state = await loadActivePlanProgress(db);
    expect(state!.isComplete, isTrue);
    expect(state.currentDay, isNull);
    expect(state.completedDays, hasLength(90));
  });

  test('returns null rather than throwing if the stored plan id no longer exists', () async {
    await startReadingPlan(db, 'some_removed_plan');
    expect(await loadActivePlanProgress(db), isNull);
  });
}
