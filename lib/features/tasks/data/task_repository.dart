import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../models/production_process.dart';
import '../models/reminder_item.dart';
import '../models/task_detail.dart';
import '../models/task_event.dart';
import '../models/task_inputs.dart';
import '../models/task_summary.dart';
import '../models/task_summary_counts.dart';

/// Formats a DateTime as "YYYY-MM-DD" — same rationale as the orders repo:
/// the backend's `today` / `expected_completion_date` are Pydantic `date`s
/// and reject full ISO datetimes.
String _dateOnly(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

class TaskRepository {
  TaskRepository(this._dio);

  final Dio _dio;

  // ── Creation ─────────────────────────────────────────────────────────────
  /// POST /order-items/{itemId}/task — the production pipeline for one
  /// item. Stage order in [stages] IS the sequence. 409 if the item
  /// already has a task.
  Future<TaskDetail> createProductionTask(
    String itemId, {
    required DateTime expectedCompletionDate,
    required List<TaskStageInput> stages,
  }) async {
    final response = await _dio.post('/order-items/$itemId/task', data: {
      'expected_completion_date': _dateOnly(expectedCompletionDate),
      'stages': stages.map((s) => s.toJson()).toList(),
    });
    return TaskDetail.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /tasks — a standalone to-do (kind 'general').
  Future<TaskDetail> createGeneralTask(GeneralTaskInput input) async {
    final response = await _dio.post('/tasks', data: input.toJson());
    return TaskDetail.fromJson(response.data as Map<String, dynamic>);
  }

  // ── List / summary / reminders ───────────────────────────────────────────
  /// GET /tasks — the mixed cross-order list. [today] and
  /// [tzOffsetMinutes] carry the CLIENT's local date and UTC offset so
  /// "due today" means the shop's today and a to-do's due *timestamp*
  /// lands on the right local calendar day (the date alone can't place a
  /// timestamp — this is why the offset param exists).
  Future<TaskListResponse> list({
    String filter = 'active',
    String? search,
    String? kind,
    required DateTime today,
    required int tzOffsetMinutes,
  }) async {
    final response = await _dio.get('/tasks', queryParameters: {
      'filter': filter,
      if (search != null && search.isNotEmpty) 'search': search,
      if (kind != null) 'kind': kind,
      'today': _dateOnly(today),
      'tz_offset_minutes': tzOffsetMinutes,
    });
    return TaskListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /tasks/summary — the Home tab's chips, same date semantics.
  Future<TaskSummaryCounts> summary({
    required DateTime today,
    required int tzOffsetMinutes,
  }) async {
    final response = await _dio.get('/tasks/summary', queryParameters: {
      'today': _dateOnly(today),
      'tz_offset_minutes': tzOffsetMinutes,
    });
    return TaskSummaryCounts.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /tasks/reminders — every open to-do with a reminder set, for the
  /// ReminderService's reconciliation pass. Returns just the rows.
  Future<List<ReminderItem>> reminders() async {
    final response = await _dio.get('/tasks/reminders');
    final data = response.data as Map<String, dynamic>;
    return (data['results'] as List)
        .map((e) => ReminderItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Detail / edit / delete ───────────────────────────────────────────────
  Future<TaskDetail> getById(String taskId) async {
    final response = await _dio.get('/tasks/$taskId');
    return TaskDetail.fromJson(response.data as Map<String, dynamic>);
  }

  /// PATCH /tasks/{id} for a PRODUCTION task — the expected date is its
  /// only editable field.
  Future<TaskDetail> updateExpectedDate(
    String taskId,
    DateTime expectedCompletionDate,
  ) async {
    final response = await _dio.patch('/tasks/$taskId', data: {
      'expected_completion_date': _dateOnly(expectedCompletionDate),
    });
    return TaskDetail.fromJson(response.data as Map<String, dynamic>);
  }

  /// PATCH /tasks/{id} for a GENERAL task. The backend clears notes / the
  /// reminder / a link on an EXPLICIT null, and ignores absent keys — so
  /// nullable params here mean "leave unchanged" and the `clear…` flags
  /// put a literal null in the body. Passing both a value and its clear
  /// flag is a programming error and asserts in debug.
  Future<TaskDetail> updateGeneralTask(
    String taskId, {
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
  }) async {
    assert(!(notes != null && clearNotes));
    assert(!(reminderMinutesBefore != null && clearReminder));
    assert(!(orderId != null && clearOrderLink));
    assert(!(clientId != null && clearClientLink));
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (clearNotes) {
      body['notes'] = null;
    } else if (notes != null) {
      body['notes'] = notes;
    }
    if (dueAt != null) body['due_at'] = dueAt.toUtc().toIso8601String();
    if (clearReminder) {
      body['reminder_minutes_before'] = null;
    } else if (reminderMinutesBefore != null) {
      body['reminder_minutes_before'] = reminderMinutesBefore;
    }
    if (clearOrderLink) {
      body['order_id'] = null;
    } else if (orderId != null) {
      body['order_id'] = orderId;
    }
    if (clearClientLink) {
      body['client_id'] = null;
    } else if (clientId != null) {
      body['client_id'] = clientId;
    }
    final response = await _dio.patch('/tasks/$taskId', data: body);
    return TaskDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(String taskId) async {
    await _dio.delete('/tasks/$taskId');
  }

  // ── To-do transitions ────────────────────────────────────────────────────
  Future<TaskDetail> complete(String taskId) async {
    final response = await _dio.post('/tasks/$taskId/complete');
    return TaskDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TaskDetail> reopen(String taskId) async {
    final response = await _dio.post('/tasks/$taskId/reopen');
    return TaskDetail.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Stage management (production) ────────────────────────────────────────
  /// POST /tasks/{id}/stages — append one untouched stage to the end.
  Future<TaskDetail> appendStage(
    String taskId, {
    required String processId,
    String? employeeId,
  }) async {
    final response = await _dio.post('/tasks/$taskId/stages', data: {
      'process_id': processId,
      if (employeeId != null) 'employee_id': employeeId,
    });
    return TaskDetail.fromJson(response.data as Map<String, dynamic>);
  }

  /// PATCH .../stages/{sid} — assign/reassign and/or move an untouched
  /// stage to a 1-based [sequence] position within the untouched tail.
  Future<TaskDetail> patchStage(
    String taskId,
    String stageId, {
    String? assignedEmployeeId,
    int? sequence,
  }) async {
    final response =
        await _dio.patch('/tasks/$taskId/stages/$stageId', data: {
      if (assignedEmployeeId != null)
        'assigned_employee_id': assignedEmployeeId,
      if (sequence != null) 'sequence': sequence,
    });
    return TaskDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TaskDetail> deleteStage(String taskId, String stageId) async {
    final response = await _dio.delete('/tasks/$taskId/stages/$stageId');
    return TaskDetail.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Stage transitions (production) ───────────────────────────────────────
  Future<TaskDetail> _stageAction(
    String taskId,
    String stageId,
    String action,
  ) async {
    final response =
        await _dio.post('/tasks/$taskId/stages/$stageId/$action');
    return TaskDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TaskDetail> startStage(String taskId, String stageId) =>
      _stageAction(taskId, stageId, 'start');

  /// The response's `handover` names the next stage + worker for the
  /// handover dialog (absent after the last stage).
  Future<TaskDetail> finishStage(String taskId, String stageId) =>
      _stageAction(taskId, stageId, 'finish');

  Future<TaskDetail> cancelStart(String taskId, String stageId) =>
      _stageAction(taskId, stageId, 'cancel-start');

  Future<TaskDetail> skipStage(String taskId, String stageId) =>
      _stageAction(taskId, stageId, 'skip');

  /// Send the task back to a FINISHED stage — later stages reset.
  Future<TaskDetail> sendBack(String taskId, String stageId) =>
      _stageAction(taskId, stageId, 'send-back');

  // ── Activity feed ────────────────────────────────────────────────────────
  /// GET /orders/{id}/task-events — the item-level half of the order
  /// detail's Activity tab, newest first; includes events for tasks that
  /// have since been deleted.
  Future<List<TaskEvent>> listOrderTaskEvents(String orderId) async {
    final response = await _dio.get('/orders/$orderId/task-events');
    final data = response.data as Map<String, dynamic>;
    return (data['results'] as List)
        .map((e) => TaskEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Process dictionary ───────────────────────────────────────────────────
  /// GET /production-processes. [active] true = only usable processes
  /// (what the create/append pickers want); null = all (the settings
  /// management screen).
  Future<List<ProductionProcess>> listProcesses({bool? active}) async {
    final response = await _dio.get('/production-processes',
        queryParameters: {if (active != null) 'active': active});
    return (response.data as List)
        .map((e) => ProductionProcess.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductionProcess> createProcess(String name,
      {int sortOrder = 0}) async {
    final response = await _dio.post('/production-processes', data: {
      'name': name,
      'sort_order': sortOrder,
    });
    return ProductionProcess.fromJson(response.data as Map<String, dynamic>);
  }

  /// Rename / reorder / deactivate — no hard delete exists server-side.
  Future<ProductionProcess> updateProcess(
    String processId, {
    String? name,
    int? sortOrder,
    bool? isActive,
  }) async {
    final response =
        await _dio.patch('/production-processes/$processId', data: {
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isActive != null) 'is_active': isActive,
    });
    return ProductionProcess.fromJson(response.data as Map<String, dynamic>);
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(dioProvider));
});
