/// Naira formatting for money the backend has already settled.
///
/// Deliberately dependency-free rather than reaching for `intl`. The app
/// renders one currency in one locale; pulling in a localisation package to
/// insert commas would be a lot of weight for a `,` and a `₦`.
///
/// Before this file the money card rendered `subtotal.toStringAsFixed(2)` —
/// so a ninety-five thousand naira order read `95000.00`, which is both
/// harder to scan and ambiguous about the unit. The rebuild's UI copy is
/// written in `₦95,000` throughout, so the formatter has to exist for that
/// copy to be implementable at all.
///
/// This does **no** rounding decisions of consequence: the figures arriving
/// from the backend are already settled to two decimal places, and the app
/// never does authoritative money math. This is presentation only.
library;

/// The naira sign, as an escape rather than a literal so the file survives
/// any tooling that mangles non-ASCII source.
const String kNairaSign = '\u20A6'; // ₦

/// A true minus sign, not a hyphen. At the font sizes used for amounts a
/// hyphen sits noticeably higher and shorter than the digits beside it.
const String _minus = '\u2212'; // −

/// `₦95,000` — or `₦9,500.50` when there are kobo.
///
/// Kobo are dropped when the amount is whole, which is the overwhelming
/// majority of tailoring figures; showing `.00` on every row is noise that
/// makes the genuinely fractional ones harder to notice. Pass
/// [alwaysShowKobo] where a fixed two-decimal column is wanted.
///
/// A negative amount renders with a leading minus (`−₦9,500`). Most callers
/// should pass an absolute value and let the row's label carry the direction
/// — the money card says `Refund due ₦9,500`, not `Refund due −₦9,500` —
/// but the sign is handled here so a stray negative can never render as
/// `₦-9500`.
String formatNaira(double amount, {bool alwaysShowKobo = false}) {
  final negative = amount < 0;
  final fixed = amount.abs().toStringAsFixed(2);
  final dot = fixed.indexOf('.');
  final whole = fixed.substring(0, dot);
  final kobo = fixed.substring(dot + 1);

  final buffer = StringBuffer();
  if (negative) buffer.write(_minus);
  buffer.write(kNairaSign);
  buffer.write(_groupThousands(whole));
  if (alwaysShowKobo || kobo != '00') {
    buffer.write('.');
    buffer.write(kobo);
  }
  return buffer.toString();
}

/// `+₦50,000` / `−₦9,500` — for the activity log, where every row has to
/// declare which way the money moved.
///
/// The explicit `+` is the point. A payment and a refund sitting in the same
/// list are only distinguishable at a glance if the inbound one is marked as
/// such; colour alone fails for the ~8% of men who can't rely on it.
String formatSignedNaira(double amount, {bool alwaysShowKobo = false}) {
  final body = formatNaira(amount.abs(), alwaysShowKobo: alwaysShowKobo);
  return amount < 0 ? '$_minus$body' : '+$body';
}

/// Renders a bare number without the currency sign — `95,000`.
/// For places where the unit is already established by a neighbouring label.
String formatAmount(double amount, {bool alwaysShowKobo = false}) {
  final formatted = formatNaira(amount, alwaysShowKobo: alwaysShowKobo);
  return formatted.replaceFirst(kNairaSign, '');
}

/// Inserts thousands separators into a run of digits: `95000` → `95,000`.
///
/// Hand-rolled rather than pulled from `intl`, for the reason at the top of
/// this file. Operates on the digit string produced by `toStringAsFixed`, so
/// it never sees a sign or a decimal point and doesn't have to defend against
/// either.
String _groupThousands(String digits) {
  if (digits.length <= 3) return digits;
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    // A comma goes before every position whose distance from the end is a
    // positive multiple of three.
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Renders a discount *value* (not an amount) without a trailing `.0`:
/// 10 stays `10`, 12.5 stays `12.5`.
///
/// Moved here from `payment_section.dart`, where it lived as a private
/// `_trimZeros`. The discount label is now built in more than one place —
/// the money card and the discount-includes-addons prompt — and two copies
/// of a formatter is how they drift.
String trimTrailingZeros(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toString();
}

/// Compact form for tight spaces — `₦148k`, `₦2.4M` — where the exact
/// figure isn't the point (e.g. a stats strip next to a headline number).
/// Every other money display in the app uses [formatNaira]; reach for this
/// one only where full precision would visually overflow.
String formatCompactNaira(double amount) {
  final negative = amount < 0;
  final abs = amount.abs();

  String value;
  if (abs >= 1000000) {
    value = '${trimTrailingZeros((abs / 1000000 * 10).round() / 10)}M';
  } else if (abs >= 1000) {
    value = '${trimTrailingZeros((abs / 1000 * 10).round() / 10)}k';
  } else {
    value = trimTrailingZeros(abs);
  }

  return '${negative ? _minus : ''}$kNairaSign$value';
}

/// The em dash used wherever a figure genuinely isn't known — specifically
/// the balance line on a receipt for a payment recorded before snapshots
/// existed. Rendering a computed number there would be a confident lie about
/// a historical figure that isn't recoverable.
const String kUnknownFigure = '\u2014'; // —

/// Formats a possibly-null figure, falling back to [kUnknownFigure].
String formatNairaOrDash(double? amount, {bool alwaysShowKobo = false}) {
  if (amount == null) return kUnknownFigure;
  return formatNaira(amount, alwaysShowKobo: alwaysShowKobo);
}
