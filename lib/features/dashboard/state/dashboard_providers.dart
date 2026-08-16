import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/fake_latency.dart';
import '../data/dashboard_repository.dart';
import '../models/dashboard_stats.dart';

/// Riverpod wiring for the Dashboard.
///
/// The screen reads four things from here:
///   • [dashboardStatsProvider]   — the range-independent payload (both tabs +
///     the leaderboard). One fetch, shared across all three tabs.
///   • [revenueRangeProvider] / [revenueCustomRangeProvider] — the revenue
///     window the user has selected (UI state that drives the fetch below).
///   • [revenueSnapshotProvider]  — the revenue block for the selected window;
///     re-fetches whenever the range or custom dates change.
///   • [leaderboardBoardProvider] — Debtors vs Top customers toggle. Pure UI
///     state; both lists already live in [dashboardStatsProvider].

/// The range-independent rollups. `autoDispose` so leaving the screen drops the
/// cache and returning re-fetches fresh figures.
final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  await fakeLatency(); // no-op unless kFakeLatency is on in a debug build
  // today + offset come from the device clock: the revenue month is the SHOP's
  // month, and the device is where the shop is (same as the Home summary).
  final now = DateTime.now();
  return ref.watch(dashboardRepositoryProvider).stats(
        today: now,
        tzOffsetMinutes: now.timeZoneOffset.inMinutes,
      );
});

/// The selected revenue window. Defaults to the current month.
final revenueRangeProvider =
    StateProvider.autoDispose<RevenueRange>((ref) => RevenueRange.month);

/// The custom from/to dates, set only when [revenueRangeProvider] is
/// [RevenueRange.custom]. Null until the user picks a range.
final revenueCustomRangeProvider =
    StateProvider.autoDispose<DateTimeRange?>((ref) => null);

/// The revenue block for the current window. Watches the range + custom-dates
/// state, so selecting a different range (or picking custom dates) triggers a
/// fresh fetch automatically.
final revenueSnapshotProvider =
    FutureProvider.autoDispose<RevenueSnapshot>((ref) async {
  final range = ref.watch(revenueRangeProvider);
  final custom = ref.watch(revenueCustomRangeProvider);
  await fakeLatency();
  final now = DateTime.now();
  final query = RevenueQuery(
    range: range,
    today: now,
    tzOffsetMinutes: now.timeZoneOffset.inMinutes,
    from: range == RevenueRange.custom ? custom?.start : null,
    to: range == RevenueRange.custom ? custom?.end : null,
  );
  return ref.watch(dashboardRepositoryProvider).revenue(query);
});

/// Which leaderboard list is showing. Both lists ship in the stats payload, so
/// this never triggers a fetch.
final leaderboardBoardProvider =
    StateProvider.autoDispose<LeaderboardBoard>((ref) => LeaderboardBoard.debtors);
