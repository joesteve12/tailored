import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_state.dart';
import '../../tasks/state/tasks_providers.dart';

/// The Home tab. Intentionally light for now — a greeting plus quick entry
/// points. The richer "due today / trials due / revenue" cards seen in the
/// reference belong to the Dashboard tab (Phase 10); this stays a launchpad
/// so it doesn't duplicate that work prematurely.
class HomeTabScreen extends ConsumerWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final businessName = (user?.businessName.isNotEmpty ?? false)
        ? user!.businessName
        : 'your shop';

    return Scaffold(
      appBar: AppBar(title: const Text('Tailored')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Welcome back',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 2),
            Text(businessName,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            const _ProductionSummary(),
            const SizedBox(height: 12),
            _QuickAction(
              icon: Icons.people_outline,
              title: 'Customers',
              subtitle: 'Find or add a customer, then start an order',
              onTap: () => context.go('/clients'),
            ),
            _QuickAction(
              icon: Icons.receipt_long_outlined,
              title: 'Orders',
              subtitle: 'Track what\'s in production',
              onTap: () => context.go('/orders'),
            ),
            _QuickAction(
              icon: Icons.groups_outlined,
              title: 'Employees',
              subtitle: 'Manage tailors and their workload',
              onTap: () => context.push('/settings/employees'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Production section: three tappable stat chips off /tasks/summary
/// (both kinds — a to-do due tomorrow is work tomorrow), each deep-linking
/// to the Tasks tab pre-filtered via the `filter` query param. Renders
/// nothing on error (Home is a launchpad, not a place for error states —
/// the Tasks tab itself surfaces failures) and a light placeholder while
/// loading.
class _ProductionSummary extends ConsumerWidget {
  const _ProductionSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(taskSummaryProvider);

    return summaryAsync.when(
      error: (_, __) => const SizedBox.shrink(),
      loading: () => const SizedBox(height: 74),
      data: (counts) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Production',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Overdue',
                  count: counts.overdue,
                  emphasis: counts.overdue > 0,
                  onTap: () => context.go('/tasks?filter=delayed'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: 'Due today',
                  count: counts.dueToday,
                  onTap: () => context.go('/tasks?filter=due_today'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: 'Due tomorrow',
                  count: counts.dueTomorrow,
                  onTap: () => context.go('/tasks?filter=due_tomorrow'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.count,
    required this.onTap,
    this.emphasis = false,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  /// Overdue > 0 gets the error tint — the one number that should nag.
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = emphasis ? scheme.errorContainer : scheme.secondaryContainer;
    final fg =
        emphasis ? scheme.onErrorContainer : scheme.onSecondaryContainer;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            children: [
              Text('$count',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: fg, fontWeight: FontWeight.w700)),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fg, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 28),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
