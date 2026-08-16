import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tasks/models/task_summary.dart';
import '../data/calendar_repository.dart';
import '../models/calendar_data.dart';

/// The month currently shown in the grid, as its first day (time stripped).
final calendarMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

/// The day the pager is focused on — a concrete day within the visible month,
/// as [TableCalendar] wants it. Distinct from [selectedDayProvider]: focus
/// drives which page shows, selection drives which day's list shows.
final focusedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// The day selected in the grid, whose list shows below.
final selectedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Events for one month, fetched as the inclusive window
/// [firstOfMonth, lastOfMonth]. Deliberately NOT autoDispose: paging keeps
/// the pager mounting/unmounting neighbouring months, and an autoDispose
/// family would refetch each one every time it scrolled back into view —
/// the network churn that made swiping feel laggy. A handful of months held
/// for the session is cheap; freshness comes from explicit invalidation
/// (pull-to-refresh, and after a to-do is completed here).
final calendarEventsProvider =
    FutureProvider.family<CalendarResponse, DateTime>((ref, month) {
  final first = DateTime(month.year, month.month, 1);
  final last = DateTime(month.year, month.month + 1, 0);
  final now = DateTime.now();
  return ref.read(calendarRepositoryProvider).events(
        from: first,
        to: last,
        today: DateTime(now.year, now.month, now.day),
        tzOffsetMinutes: now.timeZoneOffset.inMinutes,
      );
});

/// The month's events grouped by local day — computed ONCE per fetch and
/// cached, so the grid's markers and the day's list read an O(1) map instead
/// of regrouping the whole response on every rebuild (every day tap, every
/// swipe frame). Carries the underlying loading/error state through.
final calendarAgendaProvider =
    Provider.family<AsyncValue<Map<DateTime, DayAgenda>>, DateTime>(
        (ref, month) {
  return ref.watch(calendarEventsProvider(month)).whenData(buildAgenda);
});

/// The three card lists for a single day, kept separate so the day's list can
/// render each with its own list-screen card and the grid can mark the day by
/// which categories are present.
@immutable
class DayAgenda {
  const DayAgenda({
    this.orders = const [],
    this.production = const [],
    this.todos = const [],
  });

  final List<CalendarOrder> orders;
  final List<TaskSummary> production;
  final List<TaskSummary> todos;

  bool get isEmpty => orders.isEmpty && production.isEmpty && todos.isEmpty;
  int get length => orders.length + production.length + todos.length;

  /// Distinct categories present, in a stable order, for the grid's markers.
  List<String> get types => [
        if (orders.isNotEmpty) 'order',
        if (production.isNotEmpty) 'production',
        if (todos.isNotEmpty) 'todo',
      ];
}

DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

/// The local bucket day for a task: a production task's expected hand-off, or
/// a to-do's local due day. Null when the task carries no date (shouldn't
/// happen for calendar rows, but the fields are nullable on [TaskSummary]).
DateTime? taskDay(TaskSummary t) {
  if (t.isProduction) {
    final d = t.expectedCompletionDate;
    return d == null ? null : _dayKey(d);
  }
  final d = t.dueAt?.toLocal();
  return d == null ? null : _dayKey(d);
}

/// Buckets a month's response by local day. Orders sort by number, production
/// by expected date, to-dos by due time — a stable, readable order within the
/// day. Pure derivation over the fetched lists; no extra request.
Map<DateTime, DayAgenda> buildAgenda(CalendarResponse response) {
  final orders = <DateTime, List<CalendarOrder>>{};
  final production = <DateTime, List<TaskSummary>>{};
  final todos = <DateTime, List<TaskSummary>>{};

  for (final o in response.orders) {
    orders.putIfAbsent(o.day, () => []).add(o);
  }
  for (final t in response.tasks) {
    final day = taskDay(t);
    if (day == null) continue;
    (t.isProduction ? production : todos).putIfAbsent(day, () => []).add(t);
  }

  final days = {...orders.keys, ...production.keys, ...todos.keys};
  final map = <DateTime, DayAgenda>{};
  for (final day in days) {
    final o = orders[day] ?? const <CalendarOrder>[];
    final p = production[day] ?? const <TaskSummary>[];
    final g = todos[day] ?? const <TaskSummary>[];
    map[day] = DayAgenda(
      orders: [...o]..sort((a, b) => a.orderNumber.compareTo(b.orderNumber)),
      production: [...p]..sort((a, b) => (a.expectedCompletionDate ?? DateTime(0))
          .compareTo(b.expectedCompletionDate ?? DateTime(0))),
      todos: [...g]..sort(
          (a, b) => (a.dueAt ?? DateTime(0)).compareTo(b.dueAt ?? DateTime(0))),
    );
  }
  return map;
}
