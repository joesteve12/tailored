import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../orders/state/order_detail_notifier.dart';
import '../../orders/state/status_events_providers.dart';
import '../data/task_repository.dart';
import '../models/production_process.dart';
import '../models/reminder_item.dart';
import '../models/task_detail.dart';
import '../models/task_event.dart';
import '../models/task_inputs.dart';
import '../models/task_summary.dart';
import '../models/task_summary_counts.dart';

/// The Tasks tab's fetch key: filter tab + search text + optional kind
/// narrowing. A record gives free value-equality for the provider family.
typedef TaskListQuery = ({String filter, String? search, String? kind});

/// The mixed cross-order list for one query. `today` and the tz offset are
/// computed at fetch time from the device clock — the whole point of the
/// params is that "due today" means the SHOP's today, and the device is
/// where the shop is.
///
/// Plain FutureProvider (no notifier): all mutations live on
/// TaskDetailNotifier / the creation helpers below, and each of those
/// invalidates this family wholesale, so every visible filter tab
/// refetches consistently.
final taskListProvider = FutureProvider.autoDispose
    .family<TaskListResponse, TaskListQuery>((ref, query) {
  final now = DateTime.now();
  return ref.read(taskRepositoryProvider).list(
        filter: query.filter,
        search: query.search,
        kind: query.kind,
        today: now,
        tzOffsetMinutes: now.timeZoneOffset.inMinutes,
      );
});

/// The Home tab's Production chips (both kinds, same date semantics).
final taskSummaryProvider =
    FutureProvider.autoDispose<TaskSummaryCounts>((ref) {
  final now = DateTime.now();
  return ref.read(taskRepositoryProvider).summary(
        today: now,
        tzOffsetMinutes: now.timeZoneOffset.inMinutes,
      );
});

/// Every open to-do with a reminder set — the ReminderService's
/// reconciliation source. NOT autoDispose: the reconciler listens from
/// bootstrap, outside any screen's lifetime, and to-do mutations
/// invalidate it explicitly.
final taskRemindersProvider = FutureProvider<List<ReminderItem>>((ref) {
  return ref.read(taskRepositoryProvider).reminders();
});

/// The item-level half of an order's Activity tab, newest first. Same
/// family shape as `statusEventsProvider`, invalidated alongside it by
/// TaskDetailNotifier after any mutation touching that order.
final orderTaskEventsProvider =
    FutureProvider.family<List<TaskEvent>, String>((ref, orderId) {
  return ref.read(taskRepositoryProvider).listOrderTaskEvents(orderId);
});

/// Active processes only — the Create Task / append-stage pickers,
/// pre-ordered by sort_order server-side.
final activeProcessesProvider =
    FutureProvider.autoDispose<List<ProductionProcess>>((ref) {
  return ref.read(taskRepositoryProvider).listProcesses(active: true);
});

/// The full dictionary including deactivated rows — the Settings
/// management screen.
final allProcessesProvider =
    FutureProvider.autoDispose<List<ProductionProcess>>((ref) {
  return ref.read(taskRepositoryProvider).listProcesses();
});

/// Creation helpers. Creation has no detail provider to hang off (the task
/// doesn't exist yet), so these small functions own the create-then-
/// invalidate sequence. They take a [WidgetRef] — the callers are the two
/// creation screens, and WidgetRef is not assignable to Ref (they share no
/// supertype exposing `invalidate`), so typing this as Ref would make the
/// helpers uncallable from exactly the places that need them.
///
/// Both return the created TaskDetail so the caller can navigate straight
/// to it.
Future<TaskDetail> createProductionTask(
  WidgetRef ref,
  String itemId, {
  required DateTime expectedCompletionDate,
  required List<TaskStageInput> stages,
}) async {
  final detail = await ref.read(taskRepositoryProvider).createProductionTask(
        itemId,
        expectedCompletionDate: expectedCompletionDate,
        stages: stages,
      );
  ref.invalidate(taskListProvider);
  ref.invalidate(taskSummaryProvider);
  final orderId = detail.orderId;
  if (orderId != null) {
    ref.invalidate(orderDetailProvider(orderId));
    ref.invalidate(orderTaskEventsProvider(orderId));
    ref.invalidate(statusEventsProvider(orderId));
  }
  return detail;
}

Future<TaskDetail> createGeneralTask(
    WidgetRef ref, GeneralTaskInput input) async {
  final detail =
      await ref.read(taskRepositoryProvider).createGeneralTask(input);
  ref.invalidate(taskListProvider);
  ref.invalidate(taskSummaryProvider);
  ref.invalidate(taskRemindersProvider);
  final orderId = detail.orderId;
  if (orderId != null) {
    ref.invalidate(orderTaskEventsProvider(orderId));
  }
  return detail;
}
