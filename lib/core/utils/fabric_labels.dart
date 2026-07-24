/// Formats a fabric quantity + unit for display, e.g. (2.0, 'yards') -> "2 yards",
/// (1.5, 'meters') -> "1.5 meters". Trailing zeros are trimmed so whole numbers
/// read cleanly. Returns null when there's no quantity to show, so callers can
/// omit the line entirely rather than print "yards" with no number. Unit
/// defaults to yards to match the backend default.
String? formatFabricQuantity(double? quantity, String? unit) {
  if (quantity == null) return null;
  final u = (unit == null || unit.isEmpty) ? 'yards' : unit;
  // Trim trailing zeros: 2.0 -> "2", 2.50 -> "2.5", 2.25 -> "2.25".
  var n = quantity.toStringAsFixed(2);
  if (n.contains('.')) {
    n = n.replaceFirst(RegExp(r'0+$'), '');
    n = n.replaceFirst(RegExp(r'\.$'), '');
  }
  return '$n $u';
}

/// The unit options offered in the fabric editors. The backend accepts any
/// string, but the app keeps a small closed set for a clean dropdown; 'yards'
/// is the default (and the backend's default too).
const List<String> kFabricUnits = ['yards', 'meters', 'pieces'];
