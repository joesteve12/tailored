/// Response shapes for the billing endpoints the app calls (Phase 4/6 contract,
/// see PROGRESS.md). Plain classes with `fromJson`, like the other read models.
library;

/// `GET /billing/plans` → a purchasable plan and its live prices (in kobo) per
/// interval, read from the admin-editable plans table. A price changed in the
/// admin panel flows through here, so the app never hardcodes plan prices.
class PlanOption {
  const PlanOption({
    required this.planCode,
    required this.name,
    required this.monthlyKobo,
    required this.annualKobo,
  });

  factory PlanOption.fromJson(Map<String, dynamic> json) {
    return PlanOption(
      planCode: json['plan_code'] as String,
      name: json['name'] as String,
      monthlyKobo: (json['monthly_kobo'] as num?)?.toInt(),
      annualKobo: (json['annual_kobo'] as num?)?.toInt(),
    );
  }

  final String planCode;
  final String name;

  /// Price in kobo, or null when not sold at that interval.
  final int? monthlyKobo;
  final int? annualKobo;

  /// Price in naira for display (kobo ÷ 100), or null when not sold.
  double? get monthlyNaira => monthlyKobo == null ? null : monthlyKobo! / 100;
  double? get annualNaira => annualKobo == null ? null : annualKobo! / 100;

  /// The annual discount, phrased from the actual monthly/annual ratio — so it
  /// stays honest whatever prices the admin sets. Compares the annual price to
  /// paying 12× monthly:
  ///   • no saving (annual ≥ 12× monthly, or a price missing) → null (no note,
  ///     so we never claim a discount that isn't there);
  ///   • a clean whole number of months → "N month(s) free";
  ///   • otherwise → "Save N%".
  String? get annualSavingNote {
    final m = monthlyKobo;
    final a = annualKobo;
    if (m == null || a == null || m == 0) return null;
    final saving = 12 * m - a;
    if (saving <= 0) return null;
    final monthsFree = saving / m;
    final rounded = monthsFree.round();
    if (rounded >= 1 && (monthsFree - rounded).abs() < 0.05) {
      return rounded == 1 ? '1 month free' : '$rounded months free';
    }
    final pct = (saving * 100 / (12 * m)).round();
    return 'Save $pct%';
  }
}

/// `POST /billing/checkout` → the Paystack hosted-checkout handles. The app
/// opens [authorizationUrl] in a WebView; [reference] is what verify-on-return
/// passes back to confirm.
class CheckoutResponse {
  const CheckoutResponse({
    required this.authorizationUrl,
    required this.accessCode,
    required this.reference,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutResponse(
      authorizationUrl: json['authorization_url'] as String,
      accessCode: json['access_code'] as String,
      reference: json['reference'] as String,
    );
  }

  final String authorizationUrl;
  final String accessCode;
  final String reference;
}

/// `GET /billing/verify/{reference}` → the shop's subscription after
/// reconciling a returned checkout. [applied] is true when this call is what
/// activated the shop, false when a webhook (or a prior verify) already did —
/// either way [planCode]/[status] reflect the current subscription, so the
/// client can stop showing "pending".
class VerifyResponse {
  const VerifyResponse({
    required this.applied,
    required this.planCode,
    required this.status,
    required this.currentPeriodEnd,
  });

  factory VerifyResponse.fromJson(Map<String, dynamic> json) {
    return VerifyResponse(
      applied: json['applied'] as bool? ?? false,
      planCode: json['plan_code'] as String? ?? 'starter',
      status: json['status'] as String?,
      currentPeriodEnd: json['current_period_end'] as String?,
    );
  }

  final bool applied;
  final String planCode;
  final String? status;
  final String? currentPeriodEnd;

  /// True once the shop is on a paid, active plan — the signal the checkout flow
  /// treats as "payment confirmed".
  bool get isActivePaid =>
      planCode != 'starter' && (status == 'active' || status == 'trialing');
}
