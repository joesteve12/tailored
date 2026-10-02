/// The client-side mirror of a `GET /api/v1/me/promotions?placement=` payload —
/// one house-promotion card the server resolved for this shop (AD_SYSTEM Phase
/// H2/H3). The endpoint returns `null` when nothing matches; this models the
/// non-null case.
///
/// **The card is composable blocks (SDUI Level 3).** [content] is the ordered
/// block list that IS the card; the renderer (H3) maps each block to a native
/// widget. Parsing is deliberately **lenient / forward-compatible**: an
/// unrecognised block `type` is kept as-is and simply skipped at render time, and
/// a card whose [schemaVersion] is newer than this client supports is dropped
/// whole — so an older app never crashes on a newer campaign (LOCKED decision 6).
library;

/// The block-schema version this build knows how to render. A promotion whose
/// `schema_version` exceeds this is skipped entirely (forward-compat): the server
/// only bumps it on a breaking block-schema change.
const int kSupportedPromoSchemaVersion = 1;

class Promotion {
  const Promotion({
    required this.campaignId,
    required this.key,
    required this.type,
    required this.placement,
    required this.content,
    required this.card,
    required this.placementConfig,
    required this.sponsorName,
    required this.schemaVersion,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];
    final blocks = <PromoBlock>[];
    if (rawContent is List) {
      for (final entry in rawContent) {
        if (entry is Map) {
          blocks.add(PromoBlock.fromJson(entry.cast<String, dynamic>()));
        }
        // A non-object content entry is ignored, not fatal (forward-compat).
      }
    }
    final rawCard = json['card'];
    final rawCfg = json['placement_config'];
    return Promotion(
      campaignId: json['campaign_id'] as String? ?? '',
      key: json['key'] as String? ?? '',
      type: json['type'] as String? ?? 'house_feature',
      placement: json['placement'] as String? ?? '',
      content: blocks,
      card: rawCard is Map
          ? PromoCardStyle.fromJson(rawCard.cast<String, dynamic>())
          : null,
      placementConfig:
          rawCfg is Map ? rawCfg.cast<String, dynamic>() : const {},
      sponsorName: json['sponsor_name'] as String?,
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
    );
  }

  /// Campaign UUID — the address the events POST (`clicked`/`dismissed`) uses.
  final String campaignId;
  final String key;

  /// Coarse inventory type: `house_upgrade` | `house_feature` | `sponsored`.
  final String type;

  /// The slot this card fills, echoed by the server (e.g. `home_banner`).
  final String placement;

  /// The ordered block list that composes the card.
  final List<PromoBlock> content;

  /// Optional card-level style (accent, background image/gradient).
  final PromoCardStyle? card;

  /// Per-placement extras keyed by placement key (H5). Today only
  /// `in_list_card` uses it: `{"list": "orders"|"clients", "interval": N}`.
  final Map<String, dynamic> placementConfig;

  /// Sponsored campaigns only — drives the subtle "Sponsored" label (§7).
  final String? sponsorName;

  final int schemaVersion;

  bool get isSponsored => type == 'sponsored';

  /// The `in_list_card` sub-config (H5), or an empty map. `list` = which feed to
  /// inject into (`orders`/`clients`); `interval` = rows before the card.
  Map<String, dynamic> get _inListConfig {
    final c = placementConfig['in_list_card'];
    return c is Map ? c.cast<String, dynamic>() : const {};
  }

  /// Which list the in-list card targets, or null (= no constraint; the caller
  /// applies its default). `orders` | `clients`.
  String? get inListListKey => _inListConfig['list'] as String?;

  /// Rows before the injected in-list card, or null (caller uses its default).
  int? get inListInterval => (_inListConfig['interval'] as num?)?.toInt();

  /// Whether this client can safely render the card. False when it carries no
  /// blocks (nothing to show) or a block-schema version this build predates.
  bool get isRenderable =>
      content.isNotEmpty && schemaVersion <= kSupportedPromoSchemaVersion;
}

/// One block in a promotion's [Promotion.content]. Kept as a `type` + raw `props`
/// map rather than a per-type parsed class **on purpose**: the renderer reads
/// props with safe defaults and skips a type it doesn't know, so a campaign can
/// introduce new block types / new props without the model rejecting them (an
/// older client just renders what it understands). Nested blocks (a `row`'s
/// columns) are exposed via [children].
class PromoBlock {
  const PromoBlock({required this.type, required this.props});

  factory PromoBlock.fromJson(Map<String, dynamic> json) {
    return PromoBlock(
      type: json['type'] as String? ?? '',
      props: json,
    );
  }

  /// The block kind, e.g. `heading` | `paragraph` | `bullets` | `badge` |
  /// `stat` | `image` | `background` | `row` | `button` | `spacer` | `divider`.
  final String type;

  /// The block's raw fields (includes `type`). Read via the typed helpers below.
  final Map<String, dynamic> props;

  String? str(String key) {
    final v = props[key];
    return v is String && v.isNotEmpty ? v : null;
  }

  double? number(String key) {
    final v = props[key];
    return v is num ? v.toDouble() : null;
  }

  /// A block's string-list prop (e.g. a `bullets` block's `items`). Non-string
  /// entries are dropped rather than throwing.
  List<String> strings(String key) {
    final v = props[key];
    if (v is! List) return const [];
    return [for (final e in v) if (e is String) e];
  }

  /// A block's nested child blocks (e.g. a `row`/`columns` block's `children`).
  List<PromoBlock> children() {
    final v = props['children'];
    if (v is! List) return const [];
    return [
      for (final e in v)
        if (e is Map) PromoBlock.fromJson(e.cast<String, dynamic>()),
    ];
  }
}

/// Card-level styling a campaign may set (proposal §H1 `card` JSON). Every field
/// is optional — a card may lean entirely on the app's default tokens.
class PromoCardStyle {
  const PromoCardStyle({
    required this.accentHex,
    required this.backgroundImageUrl,
    required this.backgroundGradientHex,
  });

  factory PromoCardStyle.fromJson(Map<String, dynamic> json) {
    final grad = json['background_gradient'];
    return PromoCardStyle(
      accentHex: json['accent'] as String?,
      backgroundImageUrl: json['background_image'] as String?,
      backgroundGradientHex:
          grad is List ? [for (final e in grad) if (e is String) e] : null,
    );
  }

  /// Accent colour override (hex, e.g. `#B54A2A`). Falls back to the theme's
  /// primary when null/unparseable.
  final String? accentHex;

  /// Full-bleed card background image (gets an auto-scrim for text contrast).
  final String? backgroundImageUrl;

  /// Two-or-more-stop background gradient (hex stops).
  final List<String>? backgroundGradientHex;
}
