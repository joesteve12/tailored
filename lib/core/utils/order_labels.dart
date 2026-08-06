/// View-layer mapping for the orders module's string-valued enums. The wire
/// values stay exactly as the backend sends them; these helpers exist only
/// so the UI renders them consistently in one place. (Per-item production
/// labels moved with the Task system — see features/tasks/utils.)
///
/// Keeping these here, not inline in widgets, means the day the backend
/// adds a status the change is one switch arm, not a hunt across screens.
library;

/// Order-level status label (distinct from item status).
String orderStatusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'Pending';
    case 'in_progress':
      return 'In progress';
    case 'on_hold':
      return 'On hold';
    case 'ready':
      return 'Ready';
    case 'delivered':
      return 'Delivered';
    case 'cancelled':
      return 'Cancelled';
    default:
      return _titleCase(status);
  }
}

/// Allowed order-status transitions — a client-side mirror of the backend's
/// VALID_TRANSITIONS. Used to offer only the moves the backend will accept,
/// so the status menu never shows an option that 400s. The backend remains
/// the source of truth; this is purely so the UI doesn't dangle dead
/// options. A terminal status maps to an empty list (no moves left).
const Map<String, List<String>> kOrderStatusTransitions = {
  'pending': ['in_progress', 'cancelled'],
  'in_progress': ['on_hold', 'ready', 'cancelled'],
  'on_hold': ['in_progress', 'cancelled'],
  // 'ready' can go back into production: a customer may return and add a
  // garment to an order that was already finished. 'delivered' stays first
  // in the list because it's the overwhelmingly common next step, and this
  // order is the order the status menu renders.
  'ready': ['delivered', 'in_progress', 'cancelled'],
  'delivered': [],
  'cancelled': [],
};

/// The statuses an order can move to from [current], or an empty list if
/// it's terminal / unknown.
List<String> allowedOrderTransitions(String current) =>
    kOrderStatusTransitions[current] ?? const [];

/// The single "happy path" forward move from [current], if there is one —
/// the transition the status control gives visual priority to. The remaining
/// allowed transitions (put on hold, cancel, revert) are secondary. Terminal
/// or unknown statuses return null.
///
/// This is deliberately a subset of [kOrderStatusTransitions], not a
/// reordering of it: the backend still owns which moves are *allowed*; this
/// only says which allowed move is the obvious next one.
String? primaryOrderTransition(String current) {
  switch (current) {
    case 'pending':
      return 'in_progress';
    case 'in_progress':
      return 'ready';
    case 'on_hold':
      return 'in_progress';
    case 'ready':
      return 'delivered';
    default:
      return null;
  }
}

/// Verb-first label for *making* a transition, as opposed to [orderStatusLabel]
/// which names the resulting state. Used on the status-control menu items so
/// they read as actions ("Mark ready") rather than nouns ("Ready"). A few
/// depend on where you're coming from — resuming from a hold and reverting a
/// finished order both land on 'in_progress' but read differently.
String orderTransitionActionLabel(String from, String to) {
  switch (to) {
    case 'in_progress':
      if (from == 'on_hold') return 'Resume production';
      if (from == 'ready') return 'Back to production';
      return 'Start production';
    case 'on_hold':
      return 'Put on hold';
    case 'ready':
      return 'Mark ready';
    case 'delivered':
      return 'Mark delivered';
    case 'cancelled':
      return 'Cancel order';
    default:
      return orderStatusLabel(to);
  }
}

/// Priority values, lowest → highest. Wire values — render with
/// [priorityLabel]. Drives the priority selector.
const List<String> kPriorities = ['low', 'normal', 'high', 'urgent'];

String priorityLabel(String priority) {
  switch (priority) {
    case 'low':
      return 'Low';
    case 'normal':
      return 'Normal';
    case 'high':
      return 'High';
    case 'urgent':
      return 'Urgent';
    default:
      return _titleCase(priority);
  }
}

/// Order list sort options. Wire values map to the endpoint's `sort_by`
/// param (created_at | due_date | priority). `null` means the backend's
/// default ordering, surfaced to the user as "Newest first".
const List<String> kOrderSortOptions = ['created_at', 'due_date', 'priority'];

String orderSortLabel(String? sortBy) {
  switch (sortBy) {
    case 'created_at':
    case null:
      return 'Newest first';
    case 'due_date':
      return 'Due date';
    case 'priority':
      return 'Priority';
    default:
      return _titleCase(sortBy);
  }
}

/// Discount types. Wire values — render with [discountTypeLabel].
const List<String> kDiscountTypes = ['none', 'percentage', 'fixed'];

String discountTypeLabel(String type) {
  switch (type) {
    case 'none':
      return 'No discount';
    case 'percentage':
      return 'Percentage';
    case 'fixed':
      return 'Fixed amount';
    default:
      return _titleCase(type);
  }
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}
