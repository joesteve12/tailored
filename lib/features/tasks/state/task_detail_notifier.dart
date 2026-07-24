import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../orders/state/order_detail_notifier.dart';
import '../../orders/state/status_events_providers.dart';
import '../data/task_repository.dart';
import '../models/task_detail.dart';
import '../models/task_inputs.dart';
import 'tasks_providers.dart';

/// FamilyAsyncNotifier<TaskDetail, String> keyed by task id — same shape
/// and mutation philosophy as OrderDetailNotifier: granular mutations
/// adopt the returned TaskDetail without flipping to AsyncLoading (no
/// full-screen spinner for tapping Start), rethrow on failure so the
/// calling widget SnackBars and stays put; `refresh()` keeps the loading
/// behaviour for pull-to-refresh.
///
/// Every mutation fans out invalidations, because a stage transition can
/// ripple far beyond this screen: the tasks list and summary chips
/// (buckets/completeness changed), the reminders feed (a to-do edit moves
/// or removes a notification), and — when the task touches an order — the
/// order detail (auto-advance may have just moved the order's status),
/// its status-events log (the move was logged), and its task-events feed.
/// Widgets over-invalidate slightly rather than under-invalidate; these
/// are cheap refetches against filtered endpoints.
class TaskDetailNotifier extends FamilyAsyncNotifier<TaskDetail, String> {
  @override
  Future<TaskDetail> build(String taskId) {
    return ref.read(taskRepositoryProvider).getById(taskId);
  }

  TaskRepository get _repo => ref.read(taskRepositoryProvider);

  Future<void> refresh() async {
    state = const AsyncLoading<TaskDetail>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _repo.getById(arg));
  }

  void _invalidateAround(TaskDetail detail) {
    ref.invalidate(taskListProvider);
    ref.invalidate(taskSummaryProvider);
    ref.invalidate(taskRemindersProvider);
    final orderId = detail.orderId;
    if (orderId != null) {
      ref.invalidate(orderDetailProvider(orderId));
      ref.invalidate(statusEventsProvider(orderId));
      ref.invalidate(orderTaskEventsProvider(orderId));
    }
  }

  /// Runs an op returning the updated TaskDetail, adopts it, and fans out
  /// the invalidations. Returns the detail so callers that need the
  /// response (the finish flow reads `handover` off it) don't refetch.
  Future<TaskDetail> _apply(Future<TaskDetail> Function() op) async {
    final detail = await op();
    state = AsyncData(detail);
    _invalidateAround(detail);
    return detail;
  }

  // ── Task-level ───────────────────────────────────────────────────────────
  Future<void> updateExpectedDate(DateTime date) =>
      _apply(() => _repo.updateExpectedDate(arg, date));

  Future<void> updateGeneral({
    String? title,
    String? notes,
    bool clearNotes = false,
    DateTime? dueAt,
    int? reminderMinutesBefore,
    bool clearReminder = false,
    String? orderId,
    bool clearOrderLink = false,
    String? clientId,
    bool clearClientLink = false,
  }) =>
      _apply(() => _repo.updateGeneralTask(
            arg,
            title: title,
            notes: notes,
            clearNotes: clearNotes,
            dueAt: dueAt,
            reminderMinutesBefore: reminderMinutesBefore,
            clearReminder: clearReminder,
            orderId: orderId,
            clearOrderLink: clearOrderLink,
            clientId: clientId,
            clearClientLink: clearClientLink,
          ));

  Future<void> complete() => _apply(() => _repo.complete(arg));

  Future<void> reopen() => _apply(() => _repo.reopen(arg));

  /// Deletes the task. The state is left as-is (the screen pops
  /// immediately after); invalidations still fan out so the list, chips,
  /// order detail, and reminder set drop the task. Reads the current state
  /// for the order id — if the detail never loaded, there's nothing to
  /// invalidate beyond the global providers.
  Future<void> deleteTask() async {
    final current = state.valueOrNull;
    await _repo.delete(arg);
    ref.invalidate(taskListProvider);
    ref.invalidate(taskSummaryProvider);
    ref.invalidate(taskRemindersProvider);
    final orderId = current?.orderId;
    if (orderId != null) {
      ref.invalidate(orderDetailProvider(orderId));
      ref.invalidate(statusEventsProvider(orderId));
      ref.invalidate(orderTaskEventsProvider(orderId));
    }
  }

  // ── Stage management ─────────────────────────────────────────────────────
  Future<void> appendStage({required String processId, String? employeeId}) =>
      _apply(() =>
          _repo.appendStage(arg, processId: processId, employeeId: employeeId));

  Future<void> assignStage(String stageId, String employeeId) =>
      _apply(() =>
          _repo.patchStage(arg, stageId, assignedEmployeeId: employeeId));

  /// Move an untouched stage to a 1-based position within the untouched
  /// tail (the server enforces the bounds and 400s with the valid range).
  Future<void> reorderStage(String stageId, int sequence) =>
      _apply(() => _repo.patchStage(arg, stageId, sequence: sequence));

  Future<void> removeStage(String stageId) =>
      _apply(() => _repo.deleteStage(arg, stageId));

  // ── Stage transitions ────────────────────────────────────────────────────
  Future<void> start(String stageId) =>
      _apply(() => _repo.startStage(arg, stageId));

  /// Returns the updated detail so the screen can read `handover` and show
  /// the "hand the garment to …" dialog straight off the response.
  Future<TaskDetail> finish(String stageId) =>
      _apply(() => _repo.finishStage(arg, stageId));

  Future<void> cancelStart(String stageId) =>
      _apply(() => _repo.cancelStart(arg, stageId));

  Future<void> skip(String stageId) =>
      _apply(() => _repo.skipStage(arg, stageId));

  Future<void> sendBack(String stageId) =>
      _apply(() => _repo.sendBack(arg, stageId));
}

final taskDetailProvider =
    AsyncNotifierProvider.family<TaskDetailNotifier, TaskDetail, String>(
  TaskDetailNotifier.new,
);
