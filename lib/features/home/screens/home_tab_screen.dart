import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_state.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/utils/money.dart';
import '../../tasks/state/tasks_providers.dart';
import '../state/home_dashboard_providers.dart';

/// The Home tab — the shop's morning launchpad, rebuilt to the dinkee Figma.
///
/// Live sections read real providers: the greeting comes from the signed-in
/// user, and the Task Overview counts come from `taskSummaryProvider`. The
/// hero "in production" block, the revenue card, and the tasks feed are backed
/// by sample data ([homeProductionProvider] et al.) until the `GET
/// /home/summary` aggregate exists — see that provider file.
class HomeTabScreen extends ConsumerWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: const [
            _HomeHeader(),
            SizedBox(height: 12),
            _Greeting(),
            SizedBox(height: 18),
            _InProductionHero(),
            SizedBox(height: 18),
            _TaskOverviewCard(),
            SizedBox(height: 12),
            _RevenueCard(),
            SizedBox(height: 16),
            _QuickActions(),
            SizedBox(height: 20),
            _TasksSection(),
          ],
        ),
      ),
    );
  }
}

/// Serif on the display family so numerals and the greeting read as the brand
/// voice, falling back to a serif where Fraunces isn't bundled.
TextStyle _display(BuildContext context, double size,
    {Color? color, FontWeight weight = FontWeight.w500}) {
  final t = context.appTokens;
  return TextStyle(
    fontFamily: t.fontDisplay,
    fontFamilyFallback: t.fontDisplayFallback,
    fontSize: size,
    fontWeight: weight,
    color: color ?? Theme.of(context).colorScheme.onSurface,
    height: 1.05,
  );
}

/// Top bar: the two-tone DINKEE wordmark, then a theme toggle and a bell with
/// an unread dot. Not an AppBar — the Figma header scrolls with the content.
class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // DIN in the foreground colour, KEE in the brand terracotta.
        Expanded(
          child: FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6),
                children: [
                  TextSpan(
                      text: 'DIN', style: TextStyle(color: scheme.onSurface)),
                  TextSpan(
                      text: 'KEE', style: TextStyle(color: scheme.primary)),
                ],
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () =>
                  ref.read(themeModeProvider.notifier).setThemeMode(
                        isDark ? ThemeMode.light : ThemeMode.dark,
                      ),
              icon: Icon(isDark
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined),
              iconSize: 22,
              color: scheme.onSurface,
              tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            ),
            // Bell with an unread dot in the corner.
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none),
                  iconSize: 24,
                  color: scheme.onSurface,
                  tooltip: 'Notifications',
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.surface, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Date line and a time-of-day greeting, with the big calendar mark trailing.
/// Name comes from the signed-in user's business name, falling back to the
/// email handle, then a neutral 'there'.
class _Greeting extends ConsumerWidget {
  const _Greeting();

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  String _dateLine(DateTime now) =>
      '${_weekdays[now.weekday - 1]}, ${_months[now.month - 1]} ${now.day}';

  String _partOfDay(int hour) {
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final muted = context.appTokens.mutedForeground;
    final user = ref.watch(authStateProvider).valueOrNull;

    final name = (user?.businessName.isNotEmpty ?? false)
        ? user!.businessName
        : (user?.email.split('@').first ?? 'there');
    final now = DateTime.now();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_dateLine(now),
                  style: TextStyle(fontSize: 12, color: muted)),
              const SizedBox(height: 2),
              Text('${_partOfDay(now.hour)}, $name',
                  style: _display(context, 25, color: scheme.onSurface)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(Icons.calendar_month, color: scheme.onPrimary, size: 24),
        ),
      ],
    );
  }
}

/// The hero: a big serif count of orders in production, with the pipeline
/// stage breakdown as dot chips beneath. Sits on the page, not in a card.
class _InProductionHero extends ConsumerWidget {
  const _InProductionHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final muted = context.appTokens.mutedForeground;
    final snap = ref.watch(homeProductionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('${snap.ordersInProduction}',
                style: _display(context, 52, color: scheme.primary)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('orders',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface)),
                Text('in production',
                    style: TextStyle(fontSize: 13, color: muted)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (final stage in snap.stages)
              _StageChip(label: stage.label, count: stage.count),
          ],
        ),
      ],
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = context.appTokens.mutedForeground;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration:
              BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$count $label', style: TextStyle(fontSize: 12, color: muted)),
      ],
    );
  }
}

/// Task Overview — three live counts off `taskSummaryProvider`, deep-linking
/// into the Tasks tab. The three columns are flat, edge-to-edge tinted panels
/// split by hairline dividers (per the Figma): Delayed rides the error tint,
/// Due today is the accented one, Tomorrow stays neutral. Renders a light
/// placeholder while loading and nothing on error (Home is a launchpad; the
/// Tasks tab surfaces failures).
class _TaskOverviewCard extends ConsumerWidget {
  const _TaskOverviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    final summaryAsync = ref.watch(taskSummaryProvider);

    Widget shell(Widget body, {int? active}) => CustomPaint(
          // A dashed rounded border, drawn over the card so it reads like a
          // terracotta running stitch around the panel — a tailoring nod.
          foregroundPainter: _StitchBorderPainter(
            color: scheme.primary.withValues(alpha: 0.4),
            radius: tokens.radiusXl,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(tokens.radiusXl),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_box_outlined,
                              size: 14, color: scheme.primary),
                          const SizedBox(width: 6),
                          Text('TASK OVERVIEW',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.8,
                                  color: tokens.mutedForeground)),
                        ],
                      ),
                      if (active != null)
                        Text('$active active',
                            style: TextStyle(
                                fontSize: 10, color: tokens.mutedForeground)),
                    ],
                  ),
                ),
                body,
              ],
            ),
          ),
        );

    return summaryAsync.when(
      error: (_, __) => const SizedBox.shrink(),
      loading: () => shell(const SizedBox(height: 60)),
      data: (counts) {
        final divider = scheme.onSurface.withValues(alpha: 0.07);
        return shell(
          active: counts.overdue + counts.dueToday + counts.dueTomorrow,
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _OverviewColumn(
                    value: counts.overdue,
                    label: 'Delayed',
                    subtitle: 'past due',
                    tint: scheme.error.withValues(alpha: 0.09),
                    valueColor: scheme.error,
                    labelColor: scheme.onSurface,
                    onTap: () => context.go('/tasks?filter=delayed'),
                  ),
                ),
                Container(width: 1, color: divider),
                Expanded(
                  child: _OverviewColumn(
                    value: counts.dueToday,
                    label: 'Due today',
                    subtitle: 'needs action',
                    tint: scheme.primary.withValues(alpha: 0.14),
                    valueColor: scheme.primary,
                    labelColor: scheme.primary,
                    onTap: () => context.go('/tasks?filter=due_today'),
                  ),
                ),
                Container(width: 1, color: divider),
                Expanded(
                  child: _OverviewColumn(
                    value: counts.dueTomorrow,
                    label: 'Tomorrow',
                    subtitle: 'coming up',
                    tint: scheme.onSurface.withValues(alpha: 0.05),
                    valueColor: tokens.mutedForeground,
                    labelColor: scheme.onSurface,
                    onTap: () => context.go('/tasks?filter=due_tomorrow'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Strokes a dashed rounded rectangle around the Task Overview card so the
/// edge reads like a hand-sewn running stitch. Flutter's `Border` can't do
/// dashes, so we walk the rounded-rect path and lay down short dashes.
class _StitchBorderPainter extends CustomPainter {
  const _StitchBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double strokeWidth = 1.4;
  static const double dashLength = 8;
  static const double gapLength = 6;
  // How far the stitch line is pulled in from the card's edge.
  static const double inset = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Pull the stitch line in from the card edge on all sides.
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(
            inset, inset, size.width - inset * 2, size.height - inset * 2),
        Radius.circular((radius - inset).clamp(0, radius)),
      ));

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_StitchBorderPainter old) =>
      old.color != color || old.radius != radius;
}

class _OverviewColumn extends StatelessWidget {
  const _OverviewColumn({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.tint,
    required this.valueColor,
    required this.labelColor,
    required this.onTap,
  });

  final int value;
  final String label;
  final String subtitle;
  final Color tint;
  final Color valueColor;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = context.appTokens.mutedForeground;
    return Material(
      color: tint,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$value', style: _display(context, 26, color: valueColor)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: labelColor)),
              const SizedBox(height: 1),
              Text(subtitle, style: TextStyle(fontSize: 10, color: muted)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The revenue card — an intentionally dark "espresso" surface in BOTH themes
/// to match the Figma. No `ColorScheme` role stays dark in light mode, so it
/// borrows the dark-theme token values directly (keeping the palette in one
/// place). A diagonal gradient plus a soft warm glow in the top corner give it
/// depth rather than a flat fill.
class _RevenueCard extends ConsumerWidget {
  const _RevenueCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const dark = AppTokens.dark;
    final snap = ref.watch(homeRevenueProvider);

    return ClipRRect(
      borderRadius: BorderRadius.circular(context.appTokens.radiusXl),
      child: Stack(
        children: [
          // Base diagonal gradient across the dark-brown token ramp.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [dark.switchBackground, dark.muted, dark.popover],
                ),
              ),
            ),
          ),
          // Warm terracotta glow radiating from the top-left corner.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.85, -0.9),
                  radius: 1.1,
                  colors: [
                    dark.ring.withValues(alpha: 0.22),
                    Colors.transparent
                  ],
                  stops: const [0.0, 0.55],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('REVENUE · ${snap.monthLabel}',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        color: dark.mutedForeground)),
                const SizedBox(height: 6),
                Text(formatNaira(snap.amount),
                    style:
                        _display(context, 32, color: dark.popoverForeground)),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: dark.popoverForeground.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: dark.ring, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text('OUTSTANDING',
                              style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 0.6,
                                  color: dark.mutedForeground)),
                        ],
                      ),
                      Text(formatNaira(snap.outstanding),
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: dark.ring)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The three quick-entry tiles. New order routes through Customers (an order
/// always starts from a client), matching the app's real create flow.
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.inventory_2_outlined,
            label: 'Fabric',
            onTap: () => context.push('/fabrics'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: Icons.add,
            label: 'New order',
            onTap: () => context.go('/clients'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: Icons.person_add_alt,
            label: 'New client',
            onTap: () => context.push('/clients/new'),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    return Material(
      color: scheme.secondary,
      borderRadius: BorderRadius.circular(tokens.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, size: 20, color: scheme.onSecondary),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(fontSize: 11, color: scheme.onSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tasks preview: range chips (Today / This week / Next week) over a short
/// feed. Filtered client-side from [homeTaskFeedProvider]; tapping "See all"
/// opens the Tasks tab.
class _TasksSection extends ConsumerStatefulWidget {
  const _TasksSection();

  @override
  ConsumerState<_TasksSection> createState() => _TasksSectionState();
}

class _TasksSectionState extends ConsumerState<_TasksSection> {
  TaskRange _range = TaskRange.today;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = context.appTokens.mutedForeground;
    final feed = ref
        .watch(homeTaskFeedProvider)
        .where((t) => t.range == _range)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final range in TaskRange.values)
              _RangeChip(
                label: switch (range) {
                  TaskRange.today => 'Today',
                  TaskRange.thisWeek => 'This week',
                  TaskRange.nextWeek => 'Next week',
                },
                selected: _range == range,
                onTap: () => setState(() => _range = range),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('TASKS',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                    color: muted)),
            InkWell(
              onTap: () => context.go('/tasks'),
              child: Text('See all',
                  style: TextStyle(fontSize: 12, color: scheme.primary)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (feed.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text('Nothing scheduled.',
                style: TextStyle(fontSize: 13, color: muted)),
          )
        else
          for (final task in feed) _TaskRow(task: task),
      ],
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : scheme.secondary,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: selected ? scheme.onPrimary : scheme.onSecondary)),
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final HomeTaskItem task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = context.appTokens.mutedForeground;

    final (Color dot, String bucketLabel) = switch (task.bucket) {
      HomeTaskBucket.overdue => (scheme.error, 'overdue'),
      HomeTaskBucket.dueToday => (scheme.primary, 'due today'),
      HomeTaskBucket.upcoming => (context.appTokens.chart3, 'upcoming'),
    };

    return InkWell(
      onTap: () => context.go('/tasks'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${task.recipientName} — ${task.garment}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurface)),
                  const SizedBox(height: 1),
                  Text('${task.stageLabel} · $bucketLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: muted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: muted, size: 20),
          ],
        ),
      ),
    );
  }
}
