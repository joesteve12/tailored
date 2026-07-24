/// Converts a backend `Decimal` field (always serialized as a JSON string,
/// e.g. "1250.00", to preserve precision) into a Dart `double` for display
/// and simple arithmetic. The Flutter app never does authoritative money
/// math — totals and payment_status are computed server-side — so a plain
/// double is fine here; this isn't a ledger, it's a read-only display of
/// numbers the backend already settled on.
///
/// Defensively also accepts a raw num, in case a field is ever returned
/// as a JSON number instead of a Decimal-string (e.g. on a future
/// endpoint that didn't use Decimal server-side).
double decimalStringToDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.parse(value as String);
}

/// Nullable variant for measurement `value_number`, which can arrive as a
/// JSON number, a Decimal-string, or null (a value may instead be text).
double? nullableDecimalToDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value as String);
}
