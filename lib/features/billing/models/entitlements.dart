/// The shop's resolved plan, limits, live usage, and billing-clock state —
/// the client-side mirror of `GET /api/v1/me/entitlements` (extended in Phase 6
/// with the trial/renewal/saved-card fields).
///
/// Plain hand-written classes with `fromJson`, matching [ClientStats] rather
/// than the freezed models — this never crosses back to the server (read-only),
/// so codegen would just be another generated file to regenerate on every tweak.
///
/// **This is UX only.** Enforcement lives entirely in the backend (proposal §5):
/// every gate here is mirrored by a 402 on the real create/feature endpoint, so
/// a stale or bypassed snapshot never grants access — it only decides whether the
/// UI pre-empts the 402 with a friendlier prompt.
library;

/// The resolved limits + feature flags for the shop's plan. Mirrors an
/// `ENTITLEMENTS[plan_code]` entry. Numeric `null` means unlimited (Atelier);
/// `documents` is a mode string ("watermarked" | "full").
class PlanLimits {
  const PlanLimits({
    required this.activeOrders,
    required this.clients,
    required this.employees,
    required this.customProcesses,
    required this.customTemplates,
    required this.analytics,
    required this.documents,
    required this.workflowAssignment,
    required this.video,
  });

  factory PlanLimits.fromJson(Map<String, dynamic> json) {
    return PlanLimits(
      activeOrders: (json['active_orders'] as num?)?.toInt(),
      clients: (json['clients'] as num?)?.toInt(),
      employees: (json['employees'] as num?)?.toInt(),
      customProcesses: json['custom_processes'] as bool? ?? false,
      customTemplates: json['custom_templates'] as bool? ?? false,
      analytics: json['analytics'] as bool? ?? false,
      documents: json['documents'] as String? ?? 'watermarked',
      workflowAssignment: json['workflow_assignment'] as bool? ?? false,
      // Scoped video (Phase 8): false on free Starter (images-only), true on
      // Studio/Atelier. Defaults false so a shop with no row is images-only.
      video: json['video'] as bool? ?? false,
    );
  }

  /// `null` = unlimited.
  final int? activeOrders;
  final int? clients;
  final int? employees;
  final bool customProcesses;
  final bool customTemplates;
  final bool analytics;
  final String documents;
  final bool workflowAssignment;

  /// Whether the plan may attach video (order media + style references). Free
  /// Starter is images-only; Studio/Atelier allow scoped video.
  final bool video;
}

/// Live usage counts, one per numeric-limit dimension. From the same counters
/// the backend enforces against, so a meter can never disagree with its 402.
class EntitlementUsage {
  const EntitlementUsage({
    required this.activeOrders,
    required this.clients,
    required this.employees,
  });

  factory EntitlementUsage.fromJson(Map<String, dynamic> json) {
    return EntitlementUsage(
      activeOrders: (json['active_orders'] as num?)?.toInt() ?? 0,
      clients: (json['clients'] as num?)?.toInt() ?? 0,
      employees: (json['employees'] as num?)?.toInt() ?? 0,
    );
  }

  final int activeOrders;
  final int clients;
  final int employees;
}

/// The three numeric-limit dimensions the UI gates create-buttons on. The string
/// values match the JSON keys the backend uses, so a gate and its 402 name the
/// same dimension.
enum QuotaDimension {
  activeOrders('active_orders'),
  clients('clients'),
  employees('employees');

  const QuotaDimension(this.key);

  final String key;
}

class Entitlements {
  const Entitlements({
    required this.planCode,
    required this.status,
    required this.limits,
    required this.usage,
    required this.trialEnd,
    required this.currentPeriodEnd,
    required this.autoRenew,
    required this.cardLast4,
    required this.showThirdPartyAds,
    required this.promosEnabled,
  });

  factory Entitlements.fromJson(Map<String, dynamic> json) {
    return Entitlements(
      planCode: json['plan_code'] as String? ?? 'starter',
      status: json['status'] as String?,
      limits: PlanLimits.fromJson(json['limits'] as Map<String, dynamic>),
      usage: EntitlementUsage.fromJson(json['usage'] as Map<String, dynamic>),
      trialEnd: _parseDate(json['trial_end']),
      currentPeriodEnd: _parseDate(json['current_period_end']),
      autoRenew: json['auto_renew'] as bool? ?? false,
      cardLast4: json['card_last4'] as String?,
      // Ad / Promotion gates (AD_SYSTEM — Phase 0). Both default false so an
      // older server that doesn't send them, or a malformed snapshot, fails
      // CLOSED — no AdMob, no house ask — never accidentally showing ads.
      showThirdPartyAds: json['show_third_party_ads'] as bool? ?? false,
      promosEnabled: json['promos_enabled'] as bool? ?? false,
    );
  }

  final String planCode;

  /// One of trialing / active / past_due / canceled / grandfathered, or `null`
  /// when the shop has no subscription row yet (limits still resolve to Starter).
  final String? status;
  final PlanLimits limits;
  final EntitlementUsage usage;
  final DateTime? trialEnd;
  final DateTime? currentPeriodEnd;
  final bool autoRenew;
  final String? cardLast4;

  /// Server-authoritative AdMob eligibility (AD_SYSTEM — Phase 0). True only when
  /// the global `ADS_ENABLED` switch is on AND the shop is on the free tier
  /// (Starter plan or trialing status). A paid shop is always false. The client
  /// only renders AdMob when this is true — and defaults false (fails CLOSED) so
  /// ads never leak onto a paying shop while the snapshot is unknown.
  final bool showThirdPartyAds;

  /// House-promotion global switch (AD_SYSTEM — Phase 0). Whether to ask
  /// `/me/promotions` at all. NOT a plan gate — a paid shop still asks, and the
  /// server returns a campaign iff one targets its audience (may include paid
  /// tiers, e.g. announcements). Defaults false: don't ask when disabled/unknown.
  final bool promosEnabled;

  bool get isStarter => planCode == 'starter';
  bool get isStudio => planCode == 'studio';
  bool get isAtelier => planCode == 'atelier';

  bool get isTrialing => status == 'trialing';
  bool get isPastDue => status == 'past_due';

  /// Whole days from now until [trialEnd] (0 if already elapsed / no trial).
  int? get trialDaysLeft => _daysFromNow(trialEnd);

  /// Whole days from now until [currentPeriodEnd] (0 if elapsed / no period).
  int? get renewalDaysLeft => _daysFromNow(currentPeriodEnd);

  /// Human plan name for headings/badges.
  String get planLabel => switch (planCode) {
        'starter' => 'Starter',
        'studio' => 'Studio',
        'atelier' => 'Atelier',
        _ => planCode,
      };

  int? limitFor(QuotaDimension dim) => switch (dim) {
        QuotaDimension.activeOrders => limits.activeOrders,
        QuotaDimension.clients => limits.clients,
        QuotaDimension.employees => limits.employees,
      };

  int usageFor(QuotaDimension dim) => switch (dim) {
        QuotaDimension.activeOrders => usage.activeOrders,
        QuotaDimension.clients => usage.clients,
        QuotaDimension.employees => usage.employees,
      };

  /// True when the shop is **at or over** the cap for [dim] — i.e. it cannot
  /// create another. A `null` (unlimited) limit is never over. This is the
  /// create-gate test (blocking the 51st client when 50 are used); the backend's
  /// count-at-create 402 is the real enforcement.
  bool isOverLimit(QuotaDimension dim) {
    final limit = limitFor(dim);
    if (limit == null) return false;
    return usageFor(dim) >= limit;
  }

  /// True only when the shop is carrying **strictly more** than the cap for
  /// [dim] allows — the genuine read-only-over-limit state a downgrade or
  /// grandfather can produce (e.g. 8 employees on a 1-employee plan).
  ///
  /// Distinct from [isOverLimit] on purpose: a shop using *exactly* its
  /// allowance (1/1 employees, 50/50 clients) is healthy and must NOT be nagged
  /// — it just can't add more. Only this drives the over-limit banner.
  bool isExceedingLimit(QuotaDimension dim) {
    final limit = limitFor(dim);
    if (limit == null) return false;
    return usageFor(dim) > limit;
  }

  /// True if ANY numeric dimension is at/over its cap — the shop can't grow.
  bool get isAnyOverLimit => QuotaDimension.values.any(isOverLimit);

  /// True if ANY numeric dimension is *exceeded* (strictly over). Drives the
  /// over-limit banner, so a shop merely at its cap isn't told it has "hit" a
  /// limit it's actually using correctly.
  bool get isAnyExceedingLimit =>
      QuotaDimension.values.any(isExceedingLimit);

  /// Whether the Home billing banner has something to say — the exact set of
  /// states `BillingBanner._resolve` produces a card for (past-due, genuine
  /// over-limit, or a known-length trial countdown). The single source of truth
  /// for "billing pre-empts the promo slot" (AD_SYSTEM §7): the house-promo slot
  /// (`HomeBannerSlot`) reads this to know when to yield, so the two can never
  /// drift out of sync.
  bool get showsHomeBillingBanner =>
      isPastDue ||
      isAnyExceedingLimit ||
      (isTrialing && trialDaysLeft != null);

  static DateTime? _parseDate(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    // Backend sends ISO-8601 with an offset; parse to local for day math.
    return DateTime.tryParse(raw)?.toLocal();
  }

  static int? _daysFromNow(DateTime? when) {
    if (when == null) return null;
    final diff = when.difference(DateTime.now()).inSeconds;
    if (diff <= 0) return 0;
    // Round up: 0.1 days left still reads as "1 day left", never "0".
    return (diff / 86400).ceil();
  }
}
