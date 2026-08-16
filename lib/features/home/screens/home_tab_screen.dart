import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_state.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/order_labels.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/stitch_border.dart';
import '../../measurements/widgets/measurement_recipient_sheet.dart';
import '../../tasks/state/tasks_providers.dart';
import '../state/home_dashboard_providers.dart';

/// The Home tab — the shop's morning launchpad, rebuilt to the dinkee Figma.
///
/// Every section reads real providers: the greeting comes from the signed-in
/// user, the Task Overview counts come from `taskSummaryProvider`, and the
/// hero "in production" block, revenue card, and the Tasks + Orders preview
/// feeds all come from `homeSummaryProvider` (the `GET /home/summary`
/// aggregate).
class HomeTabScreen extends ConsumerWidget {
  const HomeTabScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(taskSummaryProvider);
    ref.invalidate(homeSummaryProvider);
    try {
      await Future.wait([
        ref.read(taskSummaryProvider.future),
        ref.read(homeSummaryProvider.future),
      ]);
    } catch (_) {
      // A failed refresh must still complete the pull without throwing: the
      // providers already hold the error, and each section renders its own
      // (silent) error state. Letting this propagate out of onRefresh would
      // surface as an unhandled exception / red screen.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          onRefresh: () => _refresh(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
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
              _ActivityFeeds(),
            ],
          ),
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
        // Taps through to the Calendar screen — every deadline, hand-off, and
        // to-do on one month grid.
        Material(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            onTap: () => context.push('/calendar'),
            borderRadius: BorderRadius.circular(13),
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(Icons.calendar_month,
                  color: scheme.onPrimary, size: 24),
            ),
          ),
        ),
      ],
    );
  }
}

/// Refetch both providers the dynamic Home sections read. Shared by the hero's
/// error-state Retry and mirrors what pull-to-refresh does; swallows failure so
/// a still-down backend just lands back on the error state instead of throwing.
Future<void> _retryHomeSummary(WidgetRef ref) async {
  ref.invalidate(homeSummaryProvider);
  ref.invalidate(taskSummaryProvider);
  try {
    await Future.wait([
      ref.read(homeSummaryProvider.future),
      ref.read(taskSummaryProvider.future),
    ]);
  } catch (_) {
    // The sections already render the error; nothing to do here.
  }
}

/// The hero: a big serif count of orders in production, with the pipeline
/// stage breakdown as dot chips beneath. Sits on the page, not in a card.
class _InProductionHero extends ConsumerWidget {
  const _InProductionHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(homeSummaryProvider);
    // The hero anchors the screen's single load-failure state: when the
    // summary can't be fetched (e.g. the backend is unreachable) it shows one
    // clear "couldn't reach the server" message with a Retry, so the user is
    // never left staring at a blank morning screen wondering what happened.
    // The revenue card and feeds below stay silent on error so the message
    // isn't repeated four times.
    return summaryAsync.when(
      error: (error, __) => AsyncErrorView(
        compact: true,
        error: error,
        onRetry: () => _retryHomeSummary(ref),
      ),
      loading: () => const _HeroSkeleton(),
      data: (summary) => _hero(context, summary.production),
    );
  }

  Widget _hero(BuildContext context, HomeProductionSnapshot snap) {
    final scheme = Theme.of(context).colorScheme;
    final muted = context.appTokens.mutedForeground;

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

/// Loading placeholder for the hero: a big count block, its two labels, and a
/// row of stage chips — same footprint as the real hero, so nothing shifts.
class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Skeleton(width: 56, height: 46, radius: 12),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Skeleton(width: 70, height: 14),
                  SizedBox(height: 6),
                  Skeleton(width: 92, height: 11),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              Skeleton(width: 74, height: 11),
              Skeleton(width: 88, height: 11),
              Skeleton(width: 64, height: 11),
            ],
          ),
        ],
      ),
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
          foregroundPainter: StitchBorderPainter(
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
      loading: () => shell(const _TaskOverviewSkeleton()),
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

/// Loading placeholder for the Task Overview body — three columns of a count
/// and two labels, dropped into the same `shell` the real card uses.
class _TaskOverviewSkeleton extends StatelessWidget {
  const _TaskOverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget column() => const Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 28, height: 22),
                SizedBox(height: 8),
                Skeleton(width: 54, height: 12),
                SizedBox(height: 6),
                Skeleton(width: 40, height: 9),
              ],
            ),
          ),
        );

    return Shimmer(
      child: Row(children: [column(), column(), column()]),
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
    final summaryAsync = ref.watch(homeSummaryProvider);
    // Same launchpad rule as the hero: a quiet placeholder while loading,
    // nothing on error.
    return summaryAsync.when(
      error: (_, __) => const SizedBox.shrink(),
      loading: () => _placeholder(context),
      data: (summary) => _card(context, summary.revenue),
    );
  }

  /// The card is dark in both themes, so its skeleton overrides the shimmer
  /// colours for a dark surface rather than reading the page tokens.
  Widget _placeholder(BuildContext context) {
    const dark = AppTokens.dark;
    final base = dark.muted;
    final highlight = Color.lerp(base, Colors.white, 0.12)!;
    return Container(
      height: 132,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: dark.switchBackground,
        borderRadius: BorderRadius.circular(context.appTokens.radiusXl),
      ),
      child: Shimmer(
        baseColor: base,
        highlightColor: highlight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton(width: 120, height: 11, color: base),
            const SizedBox(height: 14),
            Skeleton(width: 160, height: 28, color: base),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Skeleton(width: 90, height: 11, color: base)),
                Flexible(child: Skeleton(width: 60, height: 14, color: base)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, HomeRevenueSnapshot snap) {
    const dark = AppTokens.dark;

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
          // Full-width so the card fills the list row rather than shrinking to
          // its widest line. Only the gradient layers above are Positioned.fill;
          // this content is the Stack's sole unpositioned child, so without a
          // width it would size the whole card to the revenue figure and the
          // OUTSTANDING row below (spaceBetween) would overflow.
          SizedBox(
            width: double.infinity,
            child: Padding(
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
          ),
        ],
      ),
    );
  }
}

/// The three quick-entry tiles. "New measurement" pops a client picker (a
/// measurement always belongs to someone) and jumps straight into capture —
/// sparing the user the old route through Customers → client → measurements.
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  /// Ask who the measurement is for — a client or one of their guests — then
  /// open the capture form for them. Null means the picker was dismissed, so
  /// we stay put.
  Future<void> _startNewMeasurement(BuildContext context) async {
    final recipient = await showMeasurementRecipientSheet(context);
    if (recipient == null || !context.mounted) return;
    context.push('/measurements/new', extra: recipient);
  }

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
            icon: Icons.straighten,
            label: 'Measurement',
            onTap: () => _startNewMeasurement(context),
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

/// The Tasks + Orders preview. A single row of range chips (Overdue / Today /
/// This week / Next week) drives BOTH feeds beneath it: the Tasks list, then
/// the Orders list, each with its own "See all". One selector, so the chips
/// aren't repeated twice down the screen. Same launchpad rule as the hero: a
/// quiet placeholder while loading, silent on error.
class _ActivityFeeds extends ConsumerStatefulWidget {
  const _ActivityFeeds();

  @override
  ConsumerState<_ActivityFeeds> createState() => _ActivityFeedsState();
}

class _ActivityFeedsState extends ConsumerState<_ActivityFeeds> {
  HomeRange _range = HomeRange.today;

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(homeSummaryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final range in HomeRange.values)
              _RangeChip(
                label: _rangeLabel(range),
                selected: _range == range,
                onTap: () => setState(() => _range = range),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _FeedBlock(
          title: 'TASKS',
          onSeeAll: () => context.go('/tasks'),
          body: summaryAsync.when(
            loading: () => const _FeedPlaceholder(),
            error: (_, __) => const SizedBox.shrink(),
            data: (summary) {
              final feed =
                  summary.tasks.where((t) => t.range == _range).toList();
              if (feed.isEmpty) {
                return const _FeedEmpty(message: 'Nothing scheduled.');
              }
              return Column(
                children: [for (final task in feed) _TaskRow(task: task)],
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        _FeedBlock(
          title: 'ORDERS',
          onSeeAll: () => context.go('/orders'),
          body: summaryAsync.when(
            loading: () => const _FeedPlaceholder(),
            error: (_, __) => const SizedBox.shrink(),
            data: (summary) {
              final feed =
                  summary.orders.where((o) => o.range == _range).toList();
              if (feed.isEmpty) {
                return const _FeedEmpty(message: 'No orders due.');
              }
              return Column(
                children: [for (final order in feed) _OrderRow(order: order)],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One feed under the shared chips: a header with a "See all" link, and a
/// swappable body.
class _FeedBlock extends StatelessWidget {
  const _FeedBlock({
    required this.title,
    required this.onSeeAll,
    required this.body,
  });

  final String title;
  final VoidCallback onSeeAll;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = context.appTokens.mutedForeground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                    color: muted)),
            InkWell(
              onTap: onSeeAll,
              child: Text('See all',
                  style: TextStyle(fontSize: 12, color: scheme.primary)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        body,
      ],
    );
  }
}

/// Loading placeholder for a feed: a few rows shaped like [_FeedRow] (dot +
/// two text lines), all swept by one shimmer.
class _FeedPlaceholder extends StatelessWidget {
  const _FeedPlaceholder();

  @override
  Widget build(BuildContext context) => const Shimmer(
        child: Column(
          children: [
            _FeedRowSkeleton(),
            _FeedRowSkeleton(),
            _FeedRowSkeleton(),
          ],
        ),
      );
}

class _FeedRowSkeleton extends StatelessWidget {
  const _FeedRowSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SkeletonCircle(diameter: 8),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(width: 150, height: 13),
                  SizedBox(height: 6),
                  Skeleton(width: 96, height: 10),
                ],
              ),
            ),
          ],
        ),
      );
}

class _FeedEmpty extends StatelessWidget {
  const _FeedEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(message,
            style: TextStyle(
                fontSize: 13, color: context.appTokens.mutedForeground)),
      );
}

String _rangeLabel(HomeRange range) => switch (range) {
      HomeRange.overdue => 'Overdue',
      HomeRange.today => 'Today',
      HomeRange.thisWeek => 'This week',
      HomeRange.nextWeek => 'Next week',
    };

/// The leading-dot colour for a preview row, keyed off its range: overdue rides
/// the error tint, today the accent, and the two upcoming windows a calm chart
/// hue.
Color _rangeDotColor(BuildContext context, HomeRange range) {
  final scheme = Theme.of(context).colorScheme;
  return switch (range) {
    HomeRange.overdue => scheme.error,
    HomeRange.today => scheme.primary,
    HomeRange.thisWeek || HomeRange.nextWeek => context.appTokens.chart3,
  };
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

/// A single row in the reusable feed layout: a coloured dot, a two-line
/// title/subtitle, and a trailing chevron.
class _FeedRow extends StatelessWidget {
  const _FeedRow({
    required this.dotColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color dotColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = context.appTokens.mutedForeground;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurface)),
                  const SizedBox(height: 1),
                  Text(subtitle,
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

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final HomeTaskItem task;

  @override
  Widget build(BuildContext context) {
    final recipient = task.recipientName;
    final hasRecipient = recipient != null && recipient.isNotEmpty;
    // With a recipient, they lead and the garment folds into the subtitle;
    // otherwise the garment/errand is the title on its own.
    final title = hasRecipient ? recipient : task.title;
    final subtitle = hasRecipient
        ? '${task.title} · ${task.subtitle}'
        : task.subtitle;
    return _FeedRow(
      dotColor: _rangeDotColor(context, task.range),
      title: title,
      subtitle: subtitle,
      onTap: () => context.go('/tasks'),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final HomeOrderItem order;

  @override
  Widget build(BuildContext context) {
    final client = order.clientName;
    final hasClient = client != null && client.isNotEmpty;
    final count = order.garmentCount;
    final garments = '$count outfit${count == 1 ? '' : 's'}';
    // With a client, they lead and the order number folds into the subtitle;
    // otherwise the order number is the title.
    final title = hasClient ? client : order.orderNumber;
    final subtitle = hasClient
        ? '${order.orderNumber} · ${orderStatusLabel(order.status)} · $garments'
        : '${orderStatusLabel(order.status)} · $garments';
    return _FeedRow(
      dotColor: _rangeDotColor(context, order.range),
      title: title,
      subtitle: subtitle,
      onTap: () => context.go('/orders'),
    );
  }
}
