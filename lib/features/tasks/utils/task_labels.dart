/// View-layer mapping for the tasks module's string-valued enums. Same
/// rationale as `order_labels.dart`: wire values stay exactly as the
/// backend sends them; the UI renders them consistently in one place.
///
/// Keeping these here means the day the backend adds a stage state or a
/// task event action, the change is one switch arm, not a hunt across
/// screens.
library;

/// Stage wire-state → human label (task detail and mini-timelines).
String stageStateLabel(String state) {
  switch (state) {
    case 'untouched':
      return 'Not started';
    case 'in_progress':
      return 'In progress';
    case 'done':
      return 'Done';
    case 'skipped':
      return 'Skipped';
    default:
      return _titleCase(state);
  }
}

/// Item-level production state (the derived `production.state` block).
/// 'not_started' → "Not started"; 'in_progress' → the current stage's
/// name, with " — up next" or " — in progress" tacked on (this helper
/// takes just the state, so widgets that also have the current-stage name
/// build the composite locally — see the item chip in the order detail
/// integration in step 6).
String productionStateShortLabel(String state) {
  switch (state) {
    case 'not_started':
      return 'Not started';
    case 'in_progress':
      return 'In progress';
    case 'done':
      return 'Done';
    default:
      return _titleCase(state);
  }
}

/// TaskEvent action → human label for the Activity feed and task detail
/// events list. Kept short — the row's `detail` snapshot carries the
/// specifics (worker names, stage names, "old → new").
String taskEventActionLabel(String action) {
  switch (action) {
    case 'task_created':
      return 'Task created';
    case 'stage_assigned':
      return 'Stage assigned';
    case 'stage_started':
      return 'Stage started';
    case 'stage_start_cancelled':
      return 'Stage start cancelled';
    case 'stage_finished':
      return 'Stage finished';
    case 'stage_sent_back':
      return 'Sent back';
    case 'stage_skipped':
      return 'Stage skipped';
    case 'task_date_changed':
      return 'Date changed';
    case 'task_completed':
      return 'Completed';
    case 'task_reopened':
      return 'Reopened';
    case 'task_deleted':
      return 'Task deleted';
    default:
      return _titleCase(action);
  }
}

/// Filter-tab wire value → label for the Tasks tab.
String taskFilterLabel(String filter) {
  switch (filter) {
    case 'active':
      return 'Active';
    case 'delayed':
      return 'Delayed';
    case 'due_today':
      return 'Due today';
    case 'due_tomorrow':
      return 'Due tomorrow';
    case 'completed':
      return 'Completed';
    default:
      return _titleCase(filter);
  }
}

/// The four live filter tabs, in tab-bar order. `completed` is the
/// history view and is reached from a menu instead — never a tab.
const List<String> kTaskLiveFilters = [
  'active',
  'delayed',
  'due_today',
  'due_tomorrow',
];

/// The five reminder offset presets shown in the to-do sheet. Null =
/// "None" (no reminder). Values are minutes-before-due, matching the
/// backend's `reminder_minutes_before`.
const List<({String label, int? minutes})> kReminderPresets = [
  (label: 'None', minutes: null),
  (label: '30 minutes before', minutes: 30),
  (label: '1 hour before', minutes: 60),
  (label: '2 hours before', minutes: 120),
  (label: '1 day before', minutes: 60 * 24),
];

/// The label for a stored `reminder_minutes_before`. Falls back to a
/// derived form for values that aren't presets (a future edit surface may
/// permit arbitrary offsets), so a stray value never renders as raw
/// minutes.
String reminderOffsetLabel(int? minutesBefore) {
  if (minutesBefore == null) return 'No reminder';
  for (final preset in kReminderPresets) {
    if (preset.minutes == minutesBefore) return preset.label;
  }
  if (minutesBefore % (60 * 24) == 0) {
    final days = minutesBefore ~/ (60 * 24);
    return '$days ${days == 1 ? 'day' : 'days'} before';
  }
  if (minutesBefore % 60 == 0) {
    final hours = minutesBefore ~/ 60;
    return '$hours ${hours == 1 ? 'hour' : 'hours'} before';
  }
  return '$minutesBefore minutes before';
}

/// Human date label for a production task's `expected_completion_date` or
/// a to-do's `due_at` (on cards — the sheet uses a full picker). Compact
/// on purpose: cards are dense and the filter bucket already says which
/// day.
String taskDueDateLabel(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${date.day} ${months[date.month - 1]}';
}

/// A to-do's due time, respecting the device's 24-hour preference.
///
/// Pass `use24h: MediaQuery.alwaysUse24HourFormatOf(context)` from any
/// widget that has a [BuildContext]; pure-Dart call sites (e.g. the
/// notification body in [LocalReminderService]) default to 12-hour because
/// they have no context — acceptable, since the OS renders its own
/// notification timestamps in the system format anyway.
String dueTimeLabel(DateTime local, {bool use24h = false}) {
  final minute = local.minute.toString().padLeft(2, '0');
  if (use24h) {
    final hour = local.hour.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  final h12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final ampm = local.hour < 12 ? 'AM' : 'PM';
  return '$h12:$minute $ampm';
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value
      .split(RegExp(r'[_\s]+'))
      .map((w) => w.isEmpty ? w : (w[0].toUpperCase() + w.substring(1)))
      .join(' ');
}
