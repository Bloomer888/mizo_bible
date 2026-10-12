import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/user_database.dart';
import '../data/reading_plan_progress_repository.dart';

/// Shared between the Home card and the Reading Plans browse page --
/// both need the same "which plan, how far in" state, and both must
/// see the other's writes (starting a plan on the browse page should
/// make the Home card appear without restarting the app). Mutations
/// (startReadingPlan, markReadingPlanDayComplete) call
/// ref.invalidate(activePlanProgressProvider) themselves rather than
/// this provider watching anything reactive, since Drift's own
/// .watch() streams aren't in use elsewhere in this app either --
/// consistent with how every other repository here is read-then-
/// invalidate, not a live stream.
final activePlanProgressProvider = FutureProvider.autoDispose<ReadingPlanState?>((ref) {
  final db = ref.watch(userDatabaseProvider);
  return loadActivePlanProgress(db);
});
