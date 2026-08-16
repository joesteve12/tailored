import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_error_view.dart';
import '../models/dashboard_stats.dart';
import '../state/dashboard_providers.dart';

/// The shop-owner Dashboard, reached from Settings → Dashboard (`/dashboard`).
///
/// Every figure comes from Riverpod (see `state/dashboard_providers.dart`),
/// which reads a repository that currently serves **dummy data** shaped exactly
/// like the eventual `GET /dashboard/stats` and `GET /dashboard/revenue`
/// responses. Wiring the backend is a change confined to the repository — this
/// screen and its widgets read models, not fixtures.
///
/// Charts are fl_chart and interactive: touch a donut slice to expand it and
/// read its value in the hole; drag the trend line for per-period tooltips;
/// tap a pipeline or status bar for its count.
///
/// Three in-screen tabs, each ~one screenful:
///   • Overview   — KPI cards, orders by priority + status, client/fabric tiles
///   • Revenue    — invoiced headline, collected split, trend, leaderboard
///   • Production — pipeline bars, garment mix donut, workload-share donut
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Revenue'),
              Tab(text: 'Production'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OverviewTab(),
            _RevenueTab(),
            _ProductionTab(),
          ],
        ),
      ),
    );
  }
}

// ── The always-dark revenue/pipeline panel palette ───────────────────────────
// A couple of blocks (the invoiced hero, the pipeline chart) are deliberately
// dark in both themes — a finance-panel look — so their colors are fixed rather
// than pulled from the scheme.
const Color _panelBg = Color(0xFF241C18);
const Color _panelFg = Color(0xFFEDE5D8);
const Color _panelMuted = Color(0xFFB8A78F);
const Color _panelFaint = Color(0xFF8A7A6E);
const Color _panelHair = Color(0xFF3A2E24);
const Color _up = Color(0xFF8FCF9F);
const Color _down = Color(0xFFE8966A);
const Color _collected = Color(0xFFD4714E);
const Color _outstanding = Color(0xFF8A5C3A);
const Color _trendLine = Color(0xFFE8966A);

const List<String> _monthAbbr = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

// Fixed bar colors for the pipeline columns — they sit on the dark panel, so
// they're chosen for contrast there rather than pulled from the scheme.
const List<Color> _pipelineColors = [
  Color(0xFF8A5C3A),
  Color(0xFFD4714E),
  Color(0xFFC49A72),
  Color(0xFFB87A54),
  Color(0xFFE8C49A),
];

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  final a = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0] : '';
  final b = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
  return (a + b).toUpperCase();
}

/// Display label + chart color for an order's wire status. Colors come from the
/// warm chart ramp so the status bar matches the rest of the dashboard rather
/// than the (blue/purple/teal) semantic status swatches used on order cards.
({String label, Color color}) _statusMeta(
    String wire, AppTokens t, ColorScheme scheme) {
  switch (wire) {
    case 'pending':
      return (label: 'Pending', color: t.chart3);
    case 'in_progress':
      return (label: 'In progress', color: t.chart1);
    case 'on_hold':
      return (label: 'On hold', color: t.chart4);
    case 'ready':
      return (label: 'Ready', color: t.chart5);
    case 'delivered':
      return (label: 'Delivered', color: t.chart2);
    case 'cancelled':
      return (label: 'Cancelled', color: scheme.error);
    default:
      return (label: wire, color: t.chart2);
  }
}

/// Full-tab loading placeholder.
class _Pending extends StatelessWidget {
  const _Pending({this.height});
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// OVERVIEW
// ═════════════════════════════════════════════════════════════════════════════
class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardStatsProvider);
    return async.when(
      loading: () => const _Pending(),
      error: (e, _) => AsyncErrorView(
        error: e,
        onRetry: () async => ref.invalidate(dashboardStatsProvider),
      ),
      data: (stats) => _overview(context, stats),
    );
  }

  Widget _overview(BuildContext context, DashboardStats stats) {
    final tokens = context.appTokens;
    final scheme = Theme.of(context).colorScheme;
    final k = stats.kpis;
    final p = stats.priority;

    final statusData = [
      for (final s in stats.ordersByStatus)
        (
          meta: _statusMeta(s.status, tokens, scheme),
          count: s.count,
        ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.warning_amber_rounded,
                label: 'Overdue',
                value: '${k.overdueOrders}',
                sub: 'orders past due',
                emphasis: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.event_outlined,
                label: 'Due this week',
                value: '${k.dueThisWeekOrders}',
                sub: '${k.dueThisWeekGarments} outfits',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.content_cut,
                label: 'In production',
                value: '${k.inProduction}',
                sub: 'active orders',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.inventory_2_outlined,
                label: 'Ready',
                value: '${k.ready}',
                sub: 'awaiting pickup',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _SectionLabel('Open orders by priority'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _PriorityCell(
                count: p.urgent,
                label: 'Urgent',
                bg: scheme.errorContainer,
                fg: scheme.error,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PriorityCell(
                count: p.high,
                label: 'High',
                bg: tokens.popover,
                fg: tokens.chart1,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PriorityCell(
                count: p.normal,
                label: 'Normal',
                bg: tokens.popover,
                fg: scheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PriorityCell(
                count: p.low,
                label: 'Low',
                bg: tokens.popover,
                fg: tokens.mutedForeground,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _SectionLabel('Orders by status'),
        const SizedBox(height: 8),
        _StackedBar(
          segments: [
            for (final s in statusData) (color: s.meta.color, flex: s.count),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            for (final s in statusData)
              _LegendDot(
                color: s.meta.color,
                label: '${s.meta.label} ${s.count}',
              ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.person_add_alt,
                label: 'New clients',
                value: '${stats.newClientsThisMonth}',
                sub: 'this month',
                big: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.people_outline,
                label: 'Active clients',
                value: '${stats.activeClients}',
                sub: 'total',
                big: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.layers_outlined,
                label: 'Total fabrics',
                value: '${stats.totalFabrics}',
                sub: 'in store',
                big: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.receipt_long_outlined,
                label: 'Avg order value',
                value: formatNaira(stats.avgOrderValue),
                sub: 'this month',
                big: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// REVENUE
// ═════════════════════════════════════════════════════════════════════════════
class _RevenueTab extends ConsumerWidget {
  const _RevenueTab();

  Future<void> _pickCustom(BuildContext context, WidgetRef ref) async {
    final existing = ref.read(revenueCustomRangeProvider);
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: existing ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
    );
    if (picked != null) {
      ref.read(revenueCustomRangeProvider.notifier).state = picked;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(revenueRangeProvider);
    final custom = ref.watch(revenueCustomRangeProvider);
    // Custom needs a from/to pair before there's anything to fetch. Until the
    // user picks one, don't watch the snapshot provider at all — sending
    // `range=custom` with no dates is a 400.
    final awaitingCustomDates = range == RevenueRange.custom && custom == null;
    final statsAsync = ref.watch(dashboardStatsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _Segmented<RevenueRange>(
          expand: true,
          value: range,
          onChanged: (v) => ref.read(revenueRangeProvider.notifier).state = v,
          items: const [
            (RevenueRange.week, 'Week'),
            (RevenueRange.month, 'Month'),
            (RevenueRange.quarter, 'Quarter'),
            (RevenueRange.year, 'Year'),
            (RevenueRange.custom, 'Custom'),
          ],
        ),
        if (range == RevenueRange.custom) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _pickCustom(context, ref),
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(
              custom == null
                  ? 'Select dates'
                  : '${custom.start.day} ${_monthAbbr[custom.start.month - 1]}'
                      ' – ${custom.end.day} ${_monthAbbr[custom.end.month - 1]}',
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (awaitingCustomDates)
          const _RevenuePrompt()
        else
          ref.watch(revenueSnapshotProvider).when(
                loading: () => const _Pending(height: 260),
                error: (e, _) => AsyncErrorView(
                  error: e,
                  compact: true,
                  onRetry: () async =>
                      ref.invalidate(revenueSnapshotProvider),
                ),
                data: (d) => _RevenueHero(d),
              ),
        const SizedBox(height: 20),
        statsAsync.when(
          loading: () => const _Pending(height: 160),
          error: (e, _) => AsyncErrorView(
            error: e,
            compact: true,
            onRetry: () async => ref.invalidate(dashboardStatsProvider),
          ),
          data: (stats) => _Leaderboard(stats: stats),
        ),
      ],
    );
  }
}

/// Placeholder shown while a Custom range is selected but no dates are picked
/// yet — there's no window to fetch, so this prompts for one instead of loading.
class _RevenuePrompt extends StatelessWidget {
  const _RevenuePrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.date_range, size: 18, color: _panelMuted),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Pick a date range to see revenue',
              textAlign: TextAlign.center,
              style: TextStyle(color: _panelMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueHero extends StatelessWidget {
  const _RevenueHero(this.d);
  final RevenueSnapshot d;

  @override
  Widget build(BuildContext context) {
    final rate = d.collectedRate;
    final delta = d.revenueDeltaPct;
    final up = delta >= 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Revenue · ${d.periodLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: _panelMuted, fontSize: 12)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatNaira(d.revenue),
                        maxLines: 1,
                        style: TextStyle(
                          color: _panelFg,
                          fontSize: 28,
                          fontFamily: context.appTokens.fontDisplay,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(up ? Icons.trending_up : Icons.trending_down,
                          size: 14, color: up ? _up : _down),
                      const SizedBox(width: 3),
                      Text('${up ? '' : '−'}${delta.abs().toStringAsFixed(1)}%',
                          style:
                              TextStyle(color: up ? _up : _down, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                      'vs ${d.previousLabel} ${formatNaira(d.previousRevenue)}',
                      style: const TextStyle(color: _panelFaint, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Revenue collected',
                  style: TextStyle(color: _panelMuted, fontSize: 11)),
              Text('$rate%',
                  style: const TextStyle(color: _panelFg, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  flex: rate,
                  child: Container(height: 16, color: _collected),
                ),
                Expanded(
                  flex: 100 - rate,
                  child: Container(height: 16, color: _outstanding),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          // Wrap (not Row) so large kobo-bearing amounts stack to a second line
          // instead of overflowing — same pattern as the status legend above.
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _LegendDot(
                color: _collected,
                label: 'Collected ${formatNaira(d.collected)}',
                onPanel: true,
              ),
              _LegendDot(
                color: _outstanding,
                label: 'Outstanding ${formatNaira(d.outstanding)}',
                onPanel: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _panelHair),
          const SizedBox(height: 12),
          _TrendLineChart(points: d.trend, caption: d.trendCaption),
        ],
      ),
    );
  }
}

class _Leaderboard extends ConsumerWidget {
  const _Leaderboard({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(leaderboardBoardProvider);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Segmented<LeaderboardBoard>(
              value: board,
              onChanged: (v) =>
                  ref.read(leaderboardBoardProvider.notifier).state = v,
              items: const [
                (LeaderboardBoard.debtors, 'Debtors'),
                (LeaderboardBoard.customers, 'Top customers'),
              ],
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                board == LeaderboardBoard.debtors
                    ? 'total owed ${formatNaira(stats.totalOutstanding)}'
                    : 'orders + revenue',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 10,
                  color: board == LeaderboardBoard.debtors
                      ? scheme.error
                      : context.appTokens.mutedForeground,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _card(
          context,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: board == LeaderboardBoard.debtors
              ? _DebtorList(stats.debtors)
              : _CustomerList(stats.topCustomers),
        ),
      ],
    );
  }
}

class _DebtorList extends StatelessWidget {
  const _DebtorList(this.rows);
  final List<Debtor> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          _LeaderRow(
            last: i == rows.length - 1,
            avatarBg: scheme.error,
            initials: _initials(rows[i].name),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rows[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13)),
                      Text(
                        '${rows[i].orders} '
                        '${rows[i].orders == 1 ? 'order' : 'orders'}',
                        style: TextStyle(
                            fontSize: 11,
                            color: context.appTokens.mutedForeground),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(formatNaira(rows[i].amountOwed),
                    style: TextStyle(fontSize: 14, color: scheme.error)),
              ],
            ),
          ),
      ],
    );
  }
}

class _CustomerList extends StatelessWidget {
  const _CustomerList(this.rows);
  final List<TopCustomer> rows;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final maxScore = rows.isEmpty ? 1.0 : rows.first.score;
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          _LeaderRow(
            last: i == rows.length - 1,
            avatarBg: tokens.chart1,
            initials: _initials(rows[i].name),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(rows[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${rows[i].orders} orders · ${formatNaira(rows[i].revenue)}',
                      style: TextStyle(
                          fontSize: 11, color: tokens.mutedForeground),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: maxScore <= 0 ? 0 : rows[i].score / maxScore,
                    minHeight: 6,
                    backgroundColor: tokens.muted,
                    valueColor: AlwaysStoppedAnimation(tokens.chart1),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PRODUCTION
// ═════════════════════════════════════════════════════════════════════════════
class _ProductionTab extends ConsumerWidget {
  const _ProductionTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardStatsProvider);
    return async.when(
      loading: () => const _Pending(),
      error: (e, _) => AsyncErrorView(
        error: e,
        onRetry: () async => ref.invalidate(dashboardStatsProvider),
      ),
      data: (stats) => _production(context, stats),
    );
  }

  Widget _production(BuildContext context, DashboardStats stats) {
    final tokens = context.appTokens;
    final scheme = Theme.of(context).colorScheme;
    final chartColors = [
      tokens.chart1,
      tokens.chart2,
      tokens.chart3,
      tokens.chart4,
      tokens.chart5,
    ];

    final garmentTotal = stats.garmentMix.fold<int>(0, (a, b) => a + b.count);
    final pipelineTotal = stats.pipeline.fold<int>(0, (a, b) => a + b.count);
    final workloadTotal =
        stats.workload.fold<int>(0, (a, b) => a + b.activeStages);
    final unassigned = stats.workload
        .where((w) => w.unassigned)
        .fold<int>(0, (a, b) => a + b.activeStages);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const _SectionLabel('Production pipeline'),
            const SizedBox(width: 8),
            Flexible(
              child: Text('$pipelineTotal outfits in production',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 11, color: tokens.mutedForeground)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _PipelineBarChart(stats.pipeline),
        const SizedBox(height: 20),
        const _SectionLabel('Outfit mix', trailing: 'by quantity'),
        const SizedBox(height: 10),
        Row(
          children: [
            _DonutChart(
              total: garmentTotal,
              unit: 'outfits',
              data: [
                for (var i = 0; i < stats.garmentMix.length; i++)
                  _PieDatum(
                    stats.garmentMix[i].label,
                    stats.garmentMix[i].count.toDouble(),
                    chartColors[i % chartColors.length],
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  for (var i = 0; i < stats.garmentMix.length; i++)
                    _DonutLegendRow(
                      color: chartColors[i % chartColors.length],
                      name: stats.garmentMix[i].label,
                      trailing: '${stats.garmentMix[i].count} · '
                          '${_pct(stats.garmentMix[i].count, garmentTotal)}%',
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _SectionLabel('Workload share',
            trailing: 'active stages per tailor'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  for (var i = 0; i < stats.workload.length; i++)
                    _DonutLegendRow(
                      color: stats.workload[i].unassigned
                          ? scheme.error
                          : chartColors[i % chartColors.length],
                      name: stats.workload[i].label,
                      nameColor:
                          stats.workload[i].unassigned ? scheme.error : null,
                      trailing: '${stats.workload[i].activeStages} · '
                          '${_pct(stats.workload[i].activeStages, workloadTotal)}%',
                      trailingColor:
                          stats.workload[i].unassigned ? scheme.error : null,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _DonutChart(
              total: workloadTotal,
              unit: 'stages',
              data: [
                for (var i = 0; i < stats.workload.length; i++)
                  _PieDatum(
                    stats.workload[i].label,
                    stats.workload[i].activeStages.toDouble(),
                    stats.workload[i].unassigned
                        ? scheme.error
                        : chartColors[i % chartColors.length],
                  ),
              ],
            ),
          ],
        ),
        if (unassigned > 0) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.person_off_outlined, size: 18, color: scheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$unassigned '
                    '${unassigned == 1 ? 'stage has' : 'stages have'} '
                    'no tailor assigned',
                    style: TextStyle(fontSize: 12, color: scheme.error),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

int _pct(int part, int total) => total <= 0 ? 0 : (part / total * 100).round();

// ═════════════════════════════════════════════════════════════════════════════
// CHARTS (fl_chart)
// ═════════════════════════════════════════════════════════════════════════════

/// Interactive area-line revenue trend, on the dark panel.
///
/// Touch handling is custom rather than fl_chart's built-in, for two reasons:
///   • **Drag inside a scroll view.** A horizontal-drag recognizer competes
///     cleanly with the page's vertical scroll (each owns its axis), so you can
///     drag across the chart to scrub every period — fl_chart's pan tended to
///     lose the gesture to the surrounding ListView, leaving only taps.
///   • **Alignment.** The indicator and the x labels are both placed at the
///     same point fractions (`i/(n-1)`), so the vertical line lands exactly on
///     its label instead of drifting.
///
/// The whole plotted area is the target (not the 2px line), and the value shows
/// in a fixed readout **above** the chart so a thumb never covers it.
class _TrendLineChart extends StatefulWidget {
  const _TrendLineChart({required this.points, required this.caption});
  final List<TrendPoint> points;
  final String caption;

  @override
  State<_TrendLineChart> createState() => _TrendLineChartState();
}

class _TrendLineChartState extends State<_TrendLineChart> {
  static const double _height = 72;
  int? _touched;

  void _clear() {
    if (_touched != null) setState(() => _touched = null);
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    if (points.isEmpty) return const SizedBox(height: 90);
    final n = points.length;
    final values = points.map((p) => p.value).toList();
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final pad =
        (maxV - minV) == 0 ? (maxV.abs() * 0.1 + 1) : (maxV - minV) * 0.2;
    final minY = minV - pad;
    final maxY = maxV + pad;
    final active = _touched != null && _touched! >= 0 && _touched! < n;

    return Column(
      children: [
        // Fixed readout — updates on touch, sits above the finger.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Revenue trend',
                style: TextStyle(color: _panelMuted, fontSize: 11)),
            const SizedBox(width: 8),
            Flexible(
              child: active
                  ? Text(
                      '${points[_touched!].label} · '
                      '${formatNaira(points[_touched!].value)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                          color: _panelFg,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    )
                  : Text(widget.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style:
                          const TextStyle(color: _panelFaint, fontSize: 10)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            double xOf(int i) => n == 1 ? w / 2 : i / (n - 1) * w;
            double yOf(double v) => (1 - (v - minY) / (maxY - minY)) * _height;
            void selectFromDx(double dx) {
              final frac = (dx / w).clamp(0.0, 1.0);
              final idx = (frac * (n - 1)).round().clamp(0, n - 1);
              if (idx != _touched) setState(() => _touched = idx);
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => selectFromDx(d.localPosition.dx),
              onTapUp: (_) => _clear(),
              onTapCancel: _clear,
              onHorizontalDragStart: (d) => selectFromDx(d.localPosition.dx),
              onHorizontalDragUpdate: (d) => selectFromDx(d.localPosition.dx),
              onHorizontalDragEnd: (_) => _clear(),
              onHorizontalDragCancel: _clear,
              child: SizedBox(
                width: w,
                height: _height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: (n - 1).toDouble(),
                          minY: minY,
                          maxY: maxY,
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          lineTouchData: const LineTouchData(enabled: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                for (var i = 0; i < n; i++)
                                  FlSpot(i.toDouble(), points[i].value),
                              ],
                              isCurved: true,
                              curveSmoothness: 0.3,
                              preventCurveOverShooting: true,
                              color: _trendLine,
                              barWidth: 2,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    _trendLine.withOpacity(0.38),
                                    _trendLine.withOpacity(0.02),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (active) ...[
                      Positioned(
                        left: xOf(_touched!) - 0.5,
                        top: 0,
                        height: _height,
                        child: Container(width: 1, color: _panelMuted),
                      ),
                      Positioned(
                        left: xOf(_touched!) - 4,
                        top: yOf(points[_touched!].value) - 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _trendLine,
                            shape: BoxShape.circle,
                            border: Border.all(color: _panelBg, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        // Labels aligned to point fractions (edges pinned inward), matching the
        // indicator line above.
        SizedBox(
          width: double.infinity,
          height: 12,
          child: Stack(
            children: [
              for (var i = 0; i < n; i++)
                Align(
                  alignment: Alignment(n == 1 ? 0.0 : (2 * i / (n - 1) - 1), 0),
                  child: Text(
                    points[i].label,
                    style: TextStyle(
                      fontSize: 9,
                      color:
                          (active && i == _touched) || (!active && i == n - 1)
                              ? _panelMuted
                              : _panelFaint,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A full-width stacked proportion bar (orders-by-status).
class _StackedBar extends StatelessWidget {
  const _StackedBar({required this.segments});
  final List<({Color color, int flex})> segments;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          for (final s in segments)
            Expanded(
              flex: s.flex <= 0 ? 1 : s.flex,
              child: Container(height: 16, color: s.color),
            ),
        ],
      ),
    );
  }
}

/// The pipeline as interactive vertical bars on the dark panel. Bars sit in
/// process order (left→right flow); the busiest stage is highlighted and named
/// as the bottleneck. Tap a bar for its garment count.
class _PipelineBarChart extends StatelessWidget {
  const _PipelineBarChart(this.stages);
  final List<NamedCount> stages;

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) return const SizedBox.shrink();
    final maxCount = stages.map((s) => s.count).reduce(math.max);
    final total = stages.fold<int>(0, (a, b) => a + b.count);
    var maxIndex = 0;
    for (var i = 1; i < stages.length; i++) {
      if (stages[i].count > stages[maxIndex].count) maxIndex = i;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 132,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCount * 1.25,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= stages.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            stages[i].label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              color: i == maxIndex ? _down : _panelMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => _panelHair,
                    tooltipBorderRadius: BorderRadius.circular(8),
                    getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                      '${stages[group.x].label}\n',
                      const TextStyle(
                          color: _panelMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w400),
                      children: [
                        TextSpan(
                          text: '${rod.toY.toInt()}',
                          style: const TextStyle(
                              color: _panelFg,
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < stages.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: stages[i].count.toDouble(),
                          color: i == maxIndex
                              ? _down
                              : _pipelineColors[i % _pipelineColors.length],
                          width: 22,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1, color: _panelHair),
          const SizedBox(height: 9),
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 13, color: _down),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${stages[maxIndex].label} is the bottleneck — '
                  '${_pct(stages[maxIndex].count, total)}% of active outfits '
                  'sit here',
                  style: const TextStyle(fontSize: 10, color: _panelFaint),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One donut datum: a labelled, colored slice value.
class _PieDatum {
  const _PieDatum(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

/// Interactive donut. Touch a slice to expand it and read its label + value in
/// the hole; releasing shows the total again.
class _DonutChart extends StatefulWidget {
  const _DonutChart({
    required this.data,
    required this.total,
    required this.unit,
  });

  final List<_PieDatum> data;
  final int total;
  final String unit;

  @override
  State<_DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<_DonutChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final active = _touched >= 0 && _touched < widget.data.length;

    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response?.touchedSection == null) {
                      _touched = -1;
                      return;
                    }
                    _touched = response!.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sections: [
                for (var i = 0; i < widget.data.length; i++)
                  PieChartSectionData(
                    value: widget.data[i].value,
                    color: widget.data[i].color,
                    radius: _touched == i ? 24 : 18,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                active
                    ? '${widget.data[_touched].value.toInt()}'
                    : '${widget.total}',
                style: TextStyle(fontSize: 22, fontFamily: tokens.fontDisplay),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  active ? widget.data[_touched].label : widget.unit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: tokens.mutedForeground),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═════════════════════════════════════════════════════════════════════════════
Widget _card(BuildContext context,
    {required Widget child, EdgeInsets? padding}) {
  return Container(
    padding: padding ?? const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: context.appTokens.popover,
      borderRadius: BorderRadius.circular(context.appTokens.radiusLg),
    ),
    child: child,
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.trailing});
  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final muted = context.appTokens.mutedForeground;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(text, style: TextStyle(fontSize: 13, color: muted)),
        if (trailing != null) ...[
          const SizedBox(width: 6),
          Text('· $trailing',
              style: TextStyle(fontSize: 11, color: muted.withOpacity(0.8))),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    this.emphasis = false,
    this.big = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String sub;

  /// Overdue-style tile: error-container background, error-colored figure.
  final bool emphasis;

  /// Uses the display (serif) face for the figure — the client/fabric tiles.
  final bool big;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final scheme = Theme.of(context).colorScheme;
    final accent = emphasis ? scheme.error : scheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: emphasis ? scheme.errorContainer : tokens.popover,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 15,
                  color: emphasis ? scheme.error : tokens.mutedForeground),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            emphasis ? scheme.error : tokens.mutedForeground)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // scaleDown so a large money value (e.g. avg order value with kobo)
          // shrinks to one line rather than wrapping and unbalancing the row.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: big ? 24 : 26,
                color: accent,
                fontFamily: big ? tokens.fontDisplay : null,
              ),
            ),
          ),
          Text(sub,
              style: TextStyle(fontSize: 11, color: tokens.mutedForeground)),
        ],
      ),
    );
  }
}

class _PriorityCell extends StatelessWidget {
  const _PriorityCell({
    required this.count,
    required this.label,
    required this.bg,
    required this.fg,
  });

  final int count;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 20, color: fg)),
          Text(label, style: TextStyle(fontSize: 10, color: fg)),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.onPanel = false,
  });

  final Color color;
  final String label;

  /// Rendered on the dark panel → light text.
  final bool onPanel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 5),
        Text(label,
            style:
                TextStyle(fontSize: 11, color: onPanel ? _panelMuted : null)),
      ],
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({
    required this.avatarBg,
    required this.initials,
    required this.child,
    required this.last,
  });

  final Color avatarBg;
  final String initials;
  final Widget child;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(
                    color: context.appTokens.sidebarBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: avatarBg, shape: BoxShape.circle),
            child: Text(initials,
                style: const TextStyle(color: Color(0xFFEDE0C8), fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DonutLegendRow extends StatelessWidget {
  const _DonutLegendRow({
    required this.color,
    required this.name,
    required this.trailing,
    this.nameColor,
    this.trailingColor,
  });

  final Color color;
  final String name;
  final String trailing;
  final Color? nameColor;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    final muted = context.appTokens.mutedForeground;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: nameColor)),
          ),
          const SizedBox(width: 8),
          Text(trailing,
              style: TextStyle(fontSize: 12, color: trailingColor ?? muted)),
        ],
      ),
    );
  }
}

/// Pill segmented control. `expand: true` stretches items to fill the width
/// (the 5-way range selector); otherwise items hug their labels (the 2-way
/// leaderboard toggle).
class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.items,
    required this.value,
    required this.onChanged,
    this.expand = false,
  });

  final List<(T, String)> items;
  final T value;
  final ValueChanged<T> onChanged;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final scheme = Theme.of(context).colorScheme;

    Widget seg((T, String) item) {
      final selected = item.$1 == value;
      final cell = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(item.$1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              EdgeInsets.symmetric(vertical: 6, horizontal: expand ? 0 : 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? scheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            item.$2,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );
      return expand ? Expanded(child: cell) : cell;
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: tokens.muted,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: items.map(seg).toList(),
      ),
    );
  }
}
