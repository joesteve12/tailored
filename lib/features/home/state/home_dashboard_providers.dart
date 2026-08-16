import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/fake_latency.dart';
import '../data/home_repository.dart';

/// Home-dashboard state.
///
/// Everything the redesigned Home tab shows below the header is served by
/// `GET /home/summary` (see [homeSummaryProvider] and [HomeRepository]): the
/// "in production" hero, the revenue card, and the two preview feeds — Tasks
/// and Orders — each a short list tagged with the [HomeRange] chip it sits
/// under. The full Tasks / Orders tabs read their own list providers; these
/// feeds are just the morning preview.

/// One segment of the production pipeline breakdown under the hero count.
class ProductionStage {
  const ProductionStage(this.label, this.count);

  final String label;
  final int count;

  factory ProductionStage.fromJson(Map<String, dynamic> json) =>
      ProductionStage(json['label'] as String, json['count'] as int);
}

/// The hero "N orders / in production" block plus its stage breakdown.
/// [ordersInProduction] counts orders in the "in production" status; [stages]
/// is a separate view of where the garments in those orders currently sit, so
/// the stage counts do NOT sum back to [ordersInProduction] (one order can
/// hold several garments at different stages).
class HomeProductionSnapshot {
  const HomeProductionSnapshot({
    required this.ordersInProduction,
    required this.stages,
  });

  final int ordersInProduction;
  final List<ProductionStage> stages;

  factory HomeProductionSnapshot.fromJson(Map<String, dynamic> json) =>
      HomeProductionSnapshot(
        ordersInProduction: json['orders_in_production'] as int,
        stages: (json['stages'] as List)
            .map((e) => ProductionStage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// The revenue card: net cash collected this month and what's still
/// outstanding. Figures are naira, already-settled (the app never does money
/// math) — the same contract [formatNaira] documents.
class HomeRevenueSnapshot {
  const HomeRevenueSnapshot({
    required this.amount,
    required this.outstanding,
    required this.monthLabel,
  });

  final double amount;
  final double outstanding;
  final String monthLabel;

  factory HomeRevenueSnapshot.fromJson(Map<String, dynamic> json) =>
      HomeRevenueSnapshot(
        amount: (json['amount'] as num).toDouble(),
        outstanding: (json['outstanding'] as num).toDouble(),
        monthLabel: json['month_label'] as String,
      );
}

/// The whole `GET /home/summary` payload: the two rollups plus the Tasks and
/// Orders preview feeds the Home tab reads.
class HomeSummary {
  const HomeSummary({
    required this.production,
    required this.revenue,
    required this.tasks,
    required this.orders,
  });

  final HomeProductionSnapshot production;
  final HomeRevenueSnapshot revenue;
  final List<HomeTaskItem> tasks;
  final List<HomeOrderItem> orders;

  factory HomeSummary.fromJson(Map<String, dynamic> json) => HomeSummary(
        production: HomeProductionSnapshot.fromJson(
            json['production'] as Map<String, dynamic>),
        revenue: HomeRevenueSnapshot.fromJson(
            json['revenue'] as Map<String, dynamic>),
        tasks: (json['tasks'] as List? ?? const [])
            .map((e) => HomeTaskItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        orders: (json['orders'] as List? ?? const [])
            .map((e) => HomeOrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// The Home hero + revenue rollups. `today` and the tz offset are computed at
/// fetch time from the device clock — the whole point of the params is that
/// the revenue month is the SHOP's month, and the device is where the shop is.
final homeSummaryProvider = FutureProvider.autoDispose<HomeSummary>((ref) async {
  await fakeLatency(); // no-op unless kFakeLatency is on in a debug build
  final now = DateTime.now();
  return ref.read(homeRepositoryProvider).summary(
        today: now,
        tzOffsetMinutes: now.timeZoneOffset.inMinutes,
      );
});

/// The window a Tasks/Orders preview row sits in, and the chip the user
/// toggles between. `overdue` is its own tab, so past-due work never hides
/// under "Today". The leading-dot colour of a row is derived from this.
enum HomeRange { overdue, today, thisWeek, nextWeek }

/// Parse the backend's snake_case `range` string. Unknown values fall back to
/// [HomeRange.today] rather than throwing — a preview row is never worth a
/// crash on the morning screen.
HomeRange _rangeFromJson(String raw) {
  switch (raw) {
    case 'overdue':
      return HomeRange.overdue;
    case 'this_week':
      return HomeRange.thisWeek;
    case 'next_week':
      return HomeRange.nextWeek;
    case 'today':
    default:
      return HomeRange.today;
  }
}

/// One row in the Home Tasks preview. Covers both task kinds: [subtitle] is the
/// current stage name for a production task and "To-do" for a general one.
class HomeTaskItem {
  const HomeTaskItem({
    required this.kind,
    required this.recipientName,
    required this.title,
    required this.subtitle,
    required this.range,
  });

  /// 'production' | 'general'.
  final String kind;
  final String? recipientName;
  final String title;
  final String subtitle;
  final HomeRange range;

  factory HomeTaskItem.fromJson(Map<String, dynamic> json) => HomeTaskItem(
        kind: json['kind'] as String,
        recipientName: json['recipient_name'] as String?,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        range: _rangeFromJson(json['range'] as String),
      );
}

/// One row in the Home Orders preview — an open order bucketed by its due date.
class HomeOrderItem {
  const HomeOrderItem({
    required this.orderId,
    required this.orderNumber,
    required this.clientName,
    required this.status,
    required this.garmentCount,
    required this.range,
  });

  final String orderId;
  final String orderNumber;
  final String? clientName;

  /// Order-level status wire value (pending / in_progress / on_hold / ready) —
  /// render with `orderStatusLabel`.
  final String status;

  /// Sum of the order's item quantities.
  final int garmentCount;
  final HomeRange range;

  factory HomeOrderItem.fromJson(Map<String, dynamic> json) => HomeOrderItem(
        orderId: json['order_id'] as String,
        orderNumber: json['order_number'] as String,
        clientName: json['client_name'] as String?,
        status: json['status'] as String,
        garmentCount: json['garment_count'] as int,
        range: _rangeFromJson(json['range'] as String),
      );
}
