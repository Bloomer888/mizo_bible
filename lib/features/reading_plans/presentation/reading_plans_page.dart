import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/user_database.dart';
import '../../../core/l10n_extension.dart';
import '../data/reading_plan.dart';
import '../data/reading_plan_progress_repository.dart';
import 'reading_plan_providers.dart';

/// Browse/start screen, reached from More -- Premium only (see
/// more_page.dart's gating). Just one plan right now (see
/// allReadingPlans' own doc comment), but built as a list from day
/// one so a second plan is additive here too, not a rewrite.
class ReadingPlansPage extends ConsumerWidget {
  const ReadingPlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final activeAsync = ref.watch(activePlanProgressProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.readingPlans)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final plan in allReadingPlans)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlanCard(
                plan: plan,
                // Only attach state if THIS plan is the active one --
                // activePlanProgressProvider only ever tracks one plan
                // at a time (see its own doc comment), so every other
                // plan in the list renders as not-yet-started.
                state: activeAsync.value?.planId == plan.id ? activeAsync.value : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  final ReadingPlan plan;
  final ReadingPlanState? state;

  const _PlanCard({required this.plan, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final state = this.state;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(plan.description, style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4)),
            const SizedBox(height: 14),
            if (state == null)
              FilledButton(
                onPressed: () async {
                  await startReadingPlan(ref.read(userDatabaseProvider), plan.id);
                  ref.invalidate(activePlanProgressProvider);
                },
                child: Text(l10n.startPlan),
              )
            else if (state.isComplete)
              Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: scheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.planComplete, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
                ],
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: state.completedDays.length / plan.totalDays,
                  color: scheme.primary,
                  backgroundColor: scheme.primary.withValues(alpha: 0.14),
                ),
              ),
              const SizedBox(height: 8),
              Text(l10n.dayOfTotal(state.currentDay!, plan.totalDays), style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}
