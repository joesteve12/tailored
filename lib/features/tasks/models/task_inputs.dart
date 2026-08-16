/// NOT response models — request-building helpers, same convention as
/// [OrderItemInput]: plain classes with `toJson`, shaped so an invalid
/// request is hard to construct.

/// One stage line for production-task creation. List order IS the
/// pipeline order — the server assigns sequence 1..n from it.
class TaskStageInput {
  const TaskStageInput({required this.processId, this.employeeId});

  final String processId;

  /// Optional — an unassigned stage can't be *started* until a worker is
  /// set, but it can exist (the create screen notes this).
  final String? employeeId;

  Map<String, dynamic> toJson() => {
        'process_id': processId,
        if (employeeId != null) 'employee_id': employeeId,
      };
}

/// Matches GeneralTaskCreate — a standalone to-do. `dueAt` is converted to
/// UTC on serialization (the backend stores timestamptz); the picker works
/// in local wall-clock time and this boundary is where the conversion
/// lives, in exactly one place.
class GeneralTaskInput {
  const GeneralTaskInput({
    required this.title,
    required this.dueAt,
    this.reminderEnabled = false,
    this.notes,
    this.orderId,
    this.clientId,
  });

  final String title;
  final DateTime dueAt;

  /// Whether a reminder fires at [dueAt]. There is no offset — the reminder
  /// instant IS the due time.
  final bool reminderEnabled;
  final String? notes;
  final String? orderId;
  final String? clientId;

  Map<String, dynamic> toJson() => {
        'title': title,
        'due_at': dueAt.toUtc().toIso8601String(),
        'reminder_enabled': reminderEnabled,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        if (orderId != null) 'order_id': orderId,
        if (clientId != null) 'client_id': clientId,
      };
}
