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
