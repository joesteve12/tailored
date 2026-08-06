import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sample home-dashboard data standing in for the not-yet-built
/// `GET /home/summary` aggregate.
///
/// The "in production" hero and the revenue card need shop-wide rollups the
/// API doesn't expose yet (see the Dashboard placeholder's note about the
/// admin-stats endpoint). Until that endpoint lands, these providers return
/// fixed sample figures so the redesigned Home is structurally complete and
/// reviewable against the Figma. The Tasks feed here is likewise sample data
/// scoped to what the Home preview shows — the full Tasks tab reads the real
/// `taskListProvider`.
///
/// Swap each body for a repository call when the endpoint exists; the widget
/// layer only ever reads these types, so nothing above this file changes.

/// One segment of the production pipeline breakdown under the hero count.
class ProductionStage {
  const ProductionStage(this.label, this.count);

  final String label;
  final int count;
}

/// The hero "N orders / in production" block plus its stage breakdown.
class HomeProductionSnapshot {
  const HomeProductionSnapshot({
    required this.ordersInProduction,
    required this.stages,
  });

  final int ordersInProduction;
  final List<ProductionStage> stages;
}

/// The revenue card: money settled this month and what's still outstanding.
/// Figures are naira, already-settled (the app never does money math) — the
/// same contract [formatNaira] documents.
class HomeRevenueSnapshot {
  const HomeRevenueSnapshot({
    required this.amount,
    required this.outstanding,
    required this.monthLabel,
  });

  final double amount;
  final double outstanding;
  final String monthLabel;
}

/// The date window the Home task chips toggle between.
enum TaskRange { today, thisWeek, nextWeek }

/// Which attention bucket a task row sits in — drives the leading dot colour.
enum HomeTaskBucket { overdue, dueToday, upcoming }

/// One row in the Home tasks preview.
class HomeTaskItem {
  const HomeTaskItem({
    required this.recipientName,
    required this.garment,
    required this.stageLabel,
    required this.bucket,
    required this.range,
  });

  final String recipientName;
  final String garment;
  final String stageLabel;
  final HomeTaskBucket bucket;
  final TaskRange range;
}

// TODO(home-summary): replace with a GET /home/summary repository call.
final homeProductionProvider = Provider<HomeProductionSnapshot>((ref) {
  return const HomeProductionSnapshot(
    ordersInProduction: 6,
    stages: <ProductionStage>[
      ProductionStage('measuring', 1),
      ProductionStage('cutting', 1),
      ProductionStage('stitching', 2),
      ProductionStage('fitting', 1),
      ProductionStage('ready', 1),
    ],
  );
});

// TODO(home-summary): replace with a GET /home/summary repository call.
final homeRevenueProvider = Provider<HomeRevenueSnapshot>((ref) {
  return const HomeRevenueSnapshot(
    amount: 284000,
    outstanding: 64000,
    monthLabel: 'AUG 2026',
  );
});

// TODO(home-summary): replace with the real home tasks feed.
final homeTaskFeedProvider = Provider<List<HomeTaskItem>>((ref) {
  return const <HomeTaskItem>[
    HomeTaskItem(
      recipientName: 'Adaeze',
      garment: 'Agbada',
      stageLabel: 'Stitching',
      bucket: HomeTaskBucket.overdue,
      range: TaskRange.today,
    ),
    HomeTaskItem(
      recipientName: 'Musa',
      garment: '3-piece suit',
      stageLabel: 'Fitting',
      bucket: HomeTaskBucket.dueToday,
      range: TaskRange.today,
    ),
    HomeTaskItem(
      recipientName: 'Ngozi',
      garment: 'Aso-ebi gown',
      stageLabel: 'Cutting',
      bucket: HomeTaskBucket.dueToday,
      range: TaskRange.today,
    ),
    HomeTaskItem(
      recipientName: 'Chidi',
      garment: 'Kaftan',
      stageLabel: 'Measuring',
      bucket: HomeTaskBucket.upcoming,
      range: TaskRange.thisWeek,
    ),
    HomeTaskItem(
      recipientName: 'Tunde',
      garment: 'Senator wear',
      stageLabel: 'Stitching',
      bucket: HomeTaskBucket.upcoming,
      range: TaskRange.thisWeek,
    ),
    HomeTaskItem(
      recipientName: 'Amara',
      garment: 'Wedding dress',
      stageLabel: 'Measuring',
      bucket: HomeTaskBucket.upcoming,
      range: TaskRange.nextWeek,
    ),
  ];
});
