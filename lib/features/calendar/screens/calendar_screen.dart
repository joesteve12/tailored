import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/order_labels.dart';
import '../../../core/utils/payment_labels.dart';
import '../../../core/widgets/skeleton.dart';
import '../../orders/widgets/order_card.dart';
import '../../tasks/models/task_summary.dart';
import '../../tasks/widgets/task_card.dart';
import '../state/calendar_providers.dart';

/// The Calendar screen — a month grid of everything due, over a tap-through
/// list for the selected day. Aggregates three sources the shop already
/// tracks (order deadlines, production hand-offs, to-dos) into one view, read
/// from `GET /calendar`, and renders each with the SAME card as its list
/// screen — [OrderCard] and [TaskCard] — so nothing here is a look-alike.
///
/// The grid is a [TableCalendar]: swiping drags the neighbouring month in and
/// snaps to it, with a coloured marker per category on each day. Neighbouring
/// months are prefetched and cached (see [calendarAgendaProvider]) so paging
/// stays smooth. The whole screen scrolls vertically as one. A full-screen
/// route over the shell, reached from the Home tab's calendar mark.
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(calendarMonthProvider);
    final focusedDay = ref.watch(focusedDayProvider);
    final selectedDay = ref.watch(selectedDayProvider);

    // Markers for the visible page come from the focused month and its two
    // neighbours, merged. Watching the neighbours prefetches them, so the
    // month you swipe toward already carries its dots as it slides in.
    final prev = DateTime(month.year, month.month - 1, 1);
    final next = DateTime(month.year, month.month + 1, 1);
    final markers = <DateTime, DayAgenda>{
      ...?ref.watch(calendarAgendaProvider(prev)).valueOrNull,
      ...?ref.watch(calendarAgendaProvider(month)).valueOrNull,
      ...?ref.watch(calendarAgendaProvider(next)).valueOrNull,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            tooltip: 'Jump to today',
            icon: const Icon(Icons.today_outlined),
            onPressed: () {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              ref.read(calendarMonthProvider.notifier).state =
                  DateTime(now.year, now.month, 1);
              ref.read(focusedDayProvider.notifier).state = today;
              ref.read(selectedDayProvider.notifier).state = today;
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(calendarEventsProvider(month));
          await ref.read(calendarEventsProvider(month).future);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _Calendar(
              month: month,
              focusedDay: focusedDay,
              selectedDay: selectedDay,
              markers: markers,
              onDaySelected: (selected, focused) {
                // Ignore taps on the faded days that belong to an adjacent
                // month (the six-week grid's filler). Compared against the
                // page's own `focused` day — NOT the provider — so this stays
                // correct per page without re-rendering on swipe.
                if (selected.year != focused.year ||
                    selected.month != focused.month) {
                  return;
                }
                ref.read(selectedDayProvider.notifier).state =
                    _dayKey(selected);
                ref.read(focusedDayProvider.notifier).state = focused;
              },
              onPageChanged: (focused) {
                final now = DateTime.now();
                final m = DateTime(focused.year, focused.month, 1);
                ref.read(calendarMonthProvider.notifier).state = m;
                ref.read(focusedDayProvider.notifier).state = focused;
                // Move selection into the month now on screen so the list
                // below matches what's visible — today when it's the current
                // month, else the 1st.
                ref.read(selectedDayProvider.notifier).state =
                    (m.year == now.year && m.month == now.month)
                        ? DateTime(now.year, now.month, now.day)
                        : m;
              },
            ),
            const Divider(height: 1),
            _DayList(month: month, day: selectedDay),
          ],
        ),
      ),
    );
  }
}

// ── Category colours ─────────────────────────────────────────────────────────
// The theme has no semantic green/amber roles (it's a single terracotta
// accent), so the grid's three marker categories get their own hues, tuned per
// brightness to stay legible on both grounds.
class _CatColors {
  const _CatColors(this.order, this.production, this.todo);
  final Color order;
  final Color production;
  final Color todo;

  static _CatColors of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _CatColors(
      scheme.primary,
      dark ? const Color(0xFF7FB05F) : const Color(0xFF4E7A3A),
      dark ? const Color(0xFFE0A23C) : const Color(0xFFC07A16),
    );
  }

  Color forType(String type) {
    switch (type) {
      case 'order':
        return order;
      case 'production':
        return production;
      default:
        return todo;
    }
  }
}

// ── The grid (table_calendar) ────────────────────────────────────────────────
class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.month,
    required this.focusedDay,
    required this.selectedDay,
    required this.markers,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  final DateTime month;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Map<DateTime, DayAgenda> markers;
  final OnDaySelected onDaySelected;
  final void Function(DateTime focusedDay) onPageChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.appTokens;
    final cats = _CatColors.of(context);

    return TableCalendar<String>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2035, 12, 31),
      focusedDay: focusedDay,
      currentDay: DateTime.now(),
      startingDayOfWeek: StartingDayOfWeek.monday,
      // Only horizontal gestures — vertical drags must fall through to the
      // enclosing ListView, or the page can't scroll.
      availableGestures: AvailableGestures.horizontalSwipe,
      calendarFormat: CalendarFormat.month,
      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
      // Always lay out six week-rows, so a 5-row month and a 6-row month are
      // the same height and the grid doesn't jump as you swipe between them.
      sixWeekMonthsEnforced: true,
      rowHeight: 52,
      daysOfWeekHeight: 22,
      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
      onDaySelected: onDaySelected,
      onPageChanged: onPageChanged,
      eventLoader: (day) => markers[_dayKey(day)]?.types ?? const [],
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: false,
        headerPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        titleTextStyle: theme.textTheme.titleMedium!
            .copyWith(fontWeight: FontWeight.w700),
        leftChevronIcon: Icon(Icons.chevron_left, color: scheme.onSurface),
        rightChevronIcon: Icon(Icons.chevron_right, color: scheme.onSurface),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: tokens.mutedForeground,
        ),
        weekendStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: tokens.mutedForeground,
        ),
      ),
      calendarStyle: CalendarStyle(
        isTodayHighlighted: true,
        outsideDaysVisible: true,
        defaultTextStyle: TextStyle(color: scheme.onSurface, fontSize: 13.5),
        weekendTextStyle: TextStyle(color: scheme.onSurface, fontSize: 13.5),
        outsideTextStyle: TextStyle(
          color: tokens.mutedForeground.withValues(alpha: 0.5),
          fontSize: 13.5,
        ),
        // Every cell decoration must share ONE shape: table_calendar animates
        // the cell decoration with an AnimatedContainer, and BoxDecoration.lerp
        // asserts if it has to cross between a circle and a rounded rectangle.
        // The unselected states default to circles, so pin them to the same
        // rounded rectangle the selected/today fills use.
        defaultDecoration: _cellShape(),
        weekendDecoration: _cellShape(),
        outsideDecoration: _cellShape(),
        disabledDecoration: _cellShape(),
        holidayDecoration: _cellShape(),
        todayDecoration: _cellShape(color: tokens.muted),
        todayTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
        selectedDecoration: _cellShape(color: scheme.primary),
        selectedTextStyle: TextStyle(
          color: scheme.onPrimary,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      calendarBuilders: CalendarBuilders<String>(
        markerBuilder: (context, day, types) {
          if (types.isEmpty) return null;
          final selected = isSameDay(selectedDay, day);
          return Positioned(
            bottom: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final t in types)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? scheme.onPrimary : cats.forType(t),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── The selected day's list ──────────────────────────────────────────────────
class _DayList extends ConsumerStatefulWidget {
  const _DayList({required this.month, required this.day});

  final DateTime month;
  final DateTime day;

  @override
  ConsumerState<_DayList> createState() => _DayListState();
}

class _DayListState extends ConsumerState<_DayList> {
  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
    'Saturday', 'Sunday',
  ];
  static const _monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// To-dos swiped to complete this session — filtered out on the spot so the
  /// list never rebuilds a just-dismissed [Dismissible] (which asserts) while
  /// the refetch is in flight.
  final Set<String> _completedTodoIds = {};

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final tokens = context.appTokens;
    final isToday = _dayKey(day) == _dayKey(DateTime.now());
    final header =
        '${_weekdays[day.weekday - 1]}, ${day.day} ${_monthsShort[day.month - 1]}';

    final agendaAsync = ref.watch(calendarAgendaProvider(widget.month));
    final agenda =
        agendaAsync.valueOrNull?[_dayKey(day)];

    final orders = agenda?.orders ?? const [];
    final production = agenda?.production ?? const [];
    final todos = (agenda?.todos ?? const <TaskSummary>[])
        .where((t) => !_completedTodoIds.contains(t.taskId))
        .toList();
    final count = orders.length + production.length + todos.length;
    final countLabel = count == 1 ? '1 item' : '$count items';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                header,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Text(
                isToday ? 'Today · $countLabel' : countLabel,
                style: TextStyle(fontSize: 12.5, color: tokens.mutedForeground),
              ),
            ],
          ),
        ),
        if (agendaAsync.isLoading && agenda == null)
          const _DayListLoading()
        else if (agendaAsync.hasError)
          _DayListError(
            onRetry: () =>
                ref.invalidate(calendarEventsProvider(widget.month)),
          )
        else if (count == 0)
          _EmptyDay(isToday: isToday)
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: Column(
              children: [
                for (final o in orders)
                  OrderCard(
                    orderNumber: o.orderNumber,
                    subtitle: o.clientName,
                    dueDate: o.dueDate,
                    paymentStatus: o.paymentStatus,
                    paymentStatusLabel: paymentStatusLabel(o.paymentStatus),
                    status: o.status,
                    statusLabel: orderStatusLabel(o.status),
                    priority: o.priority,
                    onTap: () => context.push('/orders/${o.id}'),
                  ),
                for (final t in production)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TaskCard(task: t),
                  ),
                for (final t in todos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TaskCard(
                      task: t,
                      onDismissed: (id) {
                        setState(() => _completedTodoIds.add(id));
                        ref.invalidate(calendarEventsProvider(widget.month));
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.isToday});
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_available_outlined,
                size: 44, color: tokens.mutedForeground),
            const SizedBox(height: 12),
            Text(
              isToday ? 'Nothing scheduled today' : 'Nothing scheduled',
              style: TextStyle(color: tokens.mutedForeground, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayListLoading extends StatelessWidget {
  const _DayListLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Skeleton(height: 84, radius: 16),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Skeleton(height: 84, radius: 16),
          ),
        ],
      ),
    );
  }
}

class _DayListError extends StatelessWidget {
  const _DayListError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 40, color: tokens.mutedForeground),
            const SizedBox(height: 12),
            Text("Couldn't load this month",
                style: TextStyle(color: tokens.mutedForeground)),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

/// A rounded-rectangle cell decoration (optionally filled). Used for every
/// day-cell state so table_calendar's decoration animation only ever lerps
/// rectangle→rectangle — never rectangle↔circle, which asserts.
BoxDecoration _cellShape({Color? color}) =>
    BoxDecoration(color: color, borderRadius: BorderRadius.circular(10));
