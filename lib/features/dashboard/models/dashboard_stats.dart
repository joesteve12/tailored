import 'package:flutter/foundation.dart';

/// Wire models for the shop-owner Dashboard.
///
/// Two payloads back the screen:
///   • [DashboardStats]   — the range-independent rollups (`GET /dashboard/stats`)
///   • [RevenueSnapshot]  — the revenue block for one window (`GET /dashboard/revenue`)
///
/// Every class carries a `fromJson` keyed to the snake_case the FastAPI backend
/// will emit, so the repository can move from dummy maps to real responses
/// without touching these definitions or the widgets that read them.

// The window the revenue block is scoped to. `custom` carries an explicit
// from/to date pair; the rest are named windows the backend resolves in the
// shop's local calendar (same tz handling as the Home summary).
enum RevenueRange { week, month, quarter, year, custom }

// Which list the leaderboard shows. Both lists ship in [DashboardStats] and are
// all-time, so toggling is pure UI state — no refetch.
enum LeaderboardBoard { debtors, customers }

double _d(Object? v) => (v as num).toDouble();
int _i(Object? v) => (v as num).toInt();

// ── GET /dashboard/stats ──────────────────────────────────────────────────────
@immutable
class DashboardStats {
  const DashboardStats({
    required this.kpis,
    required this.priority,
    required this.ordersByStatus,
    required this.garmentMix,
    required this.pipeline,
    required this.workload,
    required this.newClientsThisMonth,
    required this.activeClients,
    required this.totalFabrics,
    required this.avgOrderValue,
    required this.totalOutstanding,
    required this.debtors,
    required this.topCustomers,
  });

  final DashboardKpis kpis;
  final PriorityCounts priority;

  /// Open orders grouped by their wire status (`pending`, `in_progress`, …).
  final List<StatusCount> ordersByStatus;

  /// Garments made, grouped by garment type, highest first.
  final List<NamedCount> garmentMix;

  /// Garments in production grouped by their current stage, in process order.
  final List<NamedCount> pipeline;

  /// Active stages per tailor, plus an `unassigned` bucket (see [WorkloadShare]).
  final List<WorkloadShare> workload;

  final int newClientsThisMonth;
  final int activeClients;
  final int totalFabrics;
  final double avgOrderValue;

  /// Total naira still owed across live orders — the leaderboard's "total owed".
  final double totalOutstanding;

  final List<Debtor> debtors;

  /// Top customers, pre-ranked by the combined 50/50 score (see [TopCustomer]).
  final List<TopCustomer> topCustomers;

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
        kpis: DashboardKpis.fromJson(j['kpis'] as Map<String, dynamic>),
        priority:
            PriorityCounts.fromJson(j['priority'] as Map<String, dynamic>),
        ordersByStatus: (j['orders_by_status'] as List)
            .map((e) => StatusCount.fromJson(e as Map<String, dynamic>))
            .toList(),
        garmentMix: (j['garment_mix'] as List)
            .map((e) => NamedCount.fromJson(e as Map<String, dynamic>))
            .toList(),
        pipeline: (j['pipeline'] as List)
            .map((e) => NamedCount.fromJson(e as Map<String, dynamic>))
            .toList(),
        workload: (j['workload'] as List)
            .map((e) => WorkloadShare.fromJson(e as Map<String, dynamic>))
            .toList(),
        newClientsThisMonth: _i(j['new_clients_this_month']),
        activeClients: _i(j['active_clients']),
        totalFabrics: _i(j['total_fabrics']),
        avgOrderValue: _d(j['avg_order_value']),
        totalOutstanding: _d(j['total_outstanding']),
        debtors: (j['debtors'] as List)
            .map((e) => Debtor.fromJson(e as Map<String, dynamic>))
            .toList(),
        topCustomers: (j['top_customers'] as List)
            .map((e) => TopCustomer.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

@immutable
class DashboardKpis {
  const DashboardKpis({
    required this.overdueOrders,
    required this.dueThisWeekOrders,
    required this.dueThisWeekGarments,
    required this.inProduction,
    required this.ready,
  });

  final int overdueOrders;
  final int dueThisWeekOrders;
  final int dueThisWeekGarments;
  final int inProduction;
  final int ready;

  factory DashboardKpis.fromJson(Map<String, dynamic> j) => DashboardKpis(
        overdueOrders: _i(j['overdue_orders']),
        dueThisWeekOrders: _i(j['due_this_week_orders']),
        dueThisWeekGarments: _i(j['due_this_week_garments']),
        inProduction: _i(j['in_production']),
        ready: _i(j['ready']),
      );
}

@immutable
class PriorityCounts {
  const PriorityCounts({
    required this.urgent,
    required this.high,
    required this.normal,
    required this.low,
  });

  final int urgent;
  final int high;
  final int normal;
  final int low;

  factory PriorityCounts.fromJson(Map<String, dynamic> j) => PriorityCounts(
        urgent: _i(j['urgent']),
        high: _i(j['high']),
        normal: _i(j['normal']),
        low: _i(j['low']),
      );
}

/// A display-ready label + count (garment types, pipeline stages).
@immutable
class NamedCount {
  const NamedCount({required this.label, required this.count});
  final String label;
  final int count;

  factory NamedCount.fromJson(Map<String, dynamic> j) =>
      NamedCount(label: j['label'] as String, count: _i(j['count']));
}

/// Orders grouped by their raw wire status — the UI maps `status` to a display
/// label and color so the palette stays a client concern.
@immutable
class StatusCount {
  const StatusCount({required this.status, required this.count});
  final String status;
  final int count;

  factory StatusCount.fromJson(Map<String, dynamic> j) =>
      StatusCount(status: j['status'] as String, count: _i(j['count']));
}

/// One tailor's active-stage load, or the shop's unassigned bucket when
/// [unassigned] is true (in which case [label] is a display string like
/// "Unassigned" rather than a person's name).
@immutable
class WorkloadShare {
  const WorkloadShare({
    required this.label,
    required this.activeStages,
    required this.unassigned,
  });

  final String label;
  final int activeStages;
  final bool unassigned;

  factory WorkloadShare.fromJson(Map<String, dynamic> j) => WorkloadShare(
        label: j['label'] as String,
        activeStages: _i(j['active_stages']),
        unassigned: (j['unassigned'] as bool?) ?? false,
      );
}

@immutable
class Debtor {
  const Debtor({
    required this.name,
    required this.orders,
    required this.amountOwed,
  });

  final String name;
  final int orders;
  final double amountOwed;

  factory Debtor.fromJson(Map<String, dynamic> j) => Debtor(
        name: j['name'] as String,
        orders: _i(j['orders']),
        amountOwed: _d(j['amount_owed']),
      );
}

@immutable
class TopCustomer {
  const TopCustomer({
    required this.name,
    required this.orders,
    required this.revenue,
    required this.score,
  });

  final String name;
  final int orders;

  /// Billed revenue from this customer — the SUM of their non-cancelled orders'
  /// `total_amount`. Deliberately **not** collected cash: this ranks customers
  /// by the business they bring, independent of what they've paid so far.
  final double revenue;

  /// The combined 50/50 rank score (revenue and order count each normalized to
  /// the busiest customer, summed). Carried through so the UI can draw the
  /// relative bar without re-deriving the ranking. Rows arrive pre-sorted
  /// descending, so `topCustomers.first.score` is the max.
  final double score;

  factory TopCustomer.fromJson(Map<String, dynamic> j) => TopCustomer(
        name: j['name'] as String,
        orders: _i(j['orders']),
        revenue: _d(j['revenue']),
        score: _d(j['score']),
      );
}

// ── GET /dashboard/revenue ────────────────────────────────────────────────────
@immutable
class RevenueSnapshot {
  const RevenueSnapshot({
    required this.periodLabel,
    required this.previousLabel,
    required this.trendCaption,
    required this.revenue,
    required this.collected,
    required this.previousRevenue,
    required this.trend,
  });

  /// The window this snapshot covers, e.g. "Aug 2026" or "12 Jul – 5 Aug".
  final String periodLabel;

  /// Short name of the comparison window, e.g. "Jul" — used in the delta chip.
  final String previousLabel;

  /// Caption under the trend, e.g. "last 6 months".
  final String trendCaption;

  /// Revenue billed in the window (the headline figure). `collected` is the
  /// portion of it received so far.
  final double revenue;
  final double collected;
  final double previousRevenue;

  /// The trend series, oldest → newest; the last point is the current period.
  final List<TrendPoint> trend;

  double get outstanding {
    final owed = revenue - collected;
    return owed < 0 ? 0 : owed;
  }

  int get collectedRate =>
      revenue <= 0 ? 0 : (collected / revenue * 100).round();

  /// Signed % change of revenue vs the previous period (0 when no baseline).
  double get revenueDeltaPct => previousRevenue <= 0
      ? 0
      : (revenue - previousRevenue) / previousRevenue * 100;

  factory RevenueSnapshot.fromJson(Map<String, dynamic> j) => RevenueSnapshot(
        periodLabel: j['period_label'] as String,
        previousLabel: j['previous_label'] as String,
        trendCaption: j['trend_caption'] as String,
        revenue: _d(j['revenue']),
        collected: _d(j['collected']),
        previousRevenue: _d(j['previous_revenue']),
        trend: (j['trend'] as List)
            .map((e) => TrendPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

@immutable
class TrendPoint {
  const TrendPoint({required this.label, required this.value});
  final String label;
  final double value;

  factory TrendPoint.fromJson(Map<String, dynamic> j) =>
      TrendPoint(label: j['label'] as String, value: _d(j['value']));
}

/// The parameters the revenue block is fetched with. Turns into query params
/// for `GET /dashboard/revenue`: a named `range`, or an explicit `from`/`to`
/// pair when the range is [RevenueRange.custom]. [today] and [tzOffsetMinutes]
/// carry the CLIENT's local date + UTC offset so windows resolve in the shop's
/// calendar, not the server's — the same date semantics as `/home/summary`.
@immutable
class RevenueQuery {
  const RevenueQuery({
    required this.range,
    required this.today,
    required this.tzOffsetMinutes,
    this.from,
    this.to,
  });

  final RevenueRange range;
  final DateTime today;
  final int tzOffsetMinutes;
  final DateTime? from;
  final DateTime? to;

  bool get hasCustomDates =>
      range == RevenueRange.custom && from != null && to != null;

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'today': dateOnly(today),
      'tz_offset_minutes': tzOffsetMinutes,
    };
    if (hasCustomDates) {
      params['from'] = dateOnly(from!);
      params['to'] = dateOnly(to!);
    } else {
      params['range'] = range.name;
    }
    return params;
  }
}

/// "YYYY-MM-DD" — the backend's date params are Pydantic `date`s and reject a
/// full ISO datetime, same as the tasks/home repos.
String dateOnly(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
