import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../measurements/models/recipient_ref.dart';
import '../../measurements/widgets/measurement_list_section.dart';
import '../../orders/state/client_orders_providers.dart';
import '../../orders/widgets/client_orders_section.dart';
import '../models/client.dart';
import '../data/client_repository.dart';
import '../state/client_detail_notifier.dart';
import '../state/client_list_notifier.dart';
import '../state/client_stats_provider.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/quote_note.dart';
import '../../../core/widgets/stitch_border.dart';
import '../../../core/utils/hero_tags.dart';
import '../../../core/utils/money.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/image_viewer.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  const ClientDetailScreen({
    super.key,
    required this.clientId,
    this.initialClient,
  });

  final String clientId;

  /// The Client the caller already had, handed over via go_router's `extra`.
  ///
  /// Not an optimisation — it's what makes the avatar Hero animate at all.
  /// The HeroController pairs Heroes by tag on the FIRST frame of the route
  /// transition and never re-checks. `clientDetailProvider` is cold when we
  /// arrive from the client list, so without a seed this screen's first frame
  /// is a spinner, the destination Hero isn't in the tree, no pair is found,
  /// and Flutter runs no flight. Data landing 200ms later is too late.
  ///
  /// Null on a deep link or cold start, where there's no origin avatar to fly
  /// from anyway. The fetch below runs regardless and swaps in fresh data.
  final Client? initialClient;

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  bool _isUploadingPhoto = false;
  bool _isDeleting = false;

  Future<void> _pickAndUploadPhoto() async {
    HapticFeedback.selectionClick();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Update photo',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _PhotoSourceTile(
              icon: Icons.photo_camera_outlined,
              label: 'Take a photo',
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            _PhotoSourceTile(
              icon: Icons.photo_library_outlined,
              label: 'Choose from gallery',
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
    try {
      await ref
          .read(clientRepositoryProvider)
          .uploadPhoto(widget.clientId, File(picked.path));
      // Refetch from the server rather than trusting the upload response
      // alone — this is the actual test of the unconfirmed assumption
      // that the upload persists photo_url server-side (see
      // client_repository.dart). If the photo doesn't show up after this,
      // that assumption was wrong.
      await ref.read(clientDetailProvider(widget.clientId).notifier).refresh();
      if (mounted) {
        HapticFeedback.lightImpact();
        showSuccessSnackbar(context, 'Photo uploaded');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Photo upload failed');
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _confirmDelete() async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(Icons.warning_amber_rounded, color: scheme.error, size: 32),
        title: const Text('Delete client?'),
        content: const Text(
          'This removes their profile, guest list, and measurements. '
          'This cannot be undone.',
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: scheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    HapticFeedback.mediumImpact();
    setState(() => _isDeleting = true);
    try {
      await ref.read(clientRepositoryProvider).delete(widget.clientId);
      await ref.read(clientListProvider.notifier).refresh();
      if (mounted) {
        showSuccessSnackbar(context, 'Client deleted');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        showErrorSnackbar(context, e, action: 'Delete failed');
      }
    }
  }

  /// Hands [uri] to the OS (dialer, WhatsApp, SMS, mail client) rather than
  /// the app doing anything with it directly. `externalApplication` is the
  /// right mode here — none of these are things the app should ever try to
  /// render inline.
  Future<void> _launch(Uri uri, {required String failureMessage}) async {
    HapticFeedback.selectionClick();
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        showErrorMessage(context, failureMessage);
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e, action: failureMessage);
    }
  }

  void _call(String phone) => _launch(Uri(scheme: 'tel', path: phone),
      failureMessage: "Couldn't start a call");

  void _sms(String phone) => _launch(Uri(scheme: 'sms', path: phone),
      failureMessage: "Couldn't open Messages");

  void _whatsapp(String phone) => _launch(
        Uri.parse('https://wa.me/${_digitsOnly(phone)}'),
        failureMessage: "Couldn't open WhatsApp",
      );

  void _email(String email) => _launch(
        Uri(scheme: 'mailto', path: email),
        failureMessage: "Couldn't open Email",
      );

  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(clientDetailProvider(widget.clientId));

    // Prefer live data; fall back to whatever the caller handed us. The point
    // is that this is non-null on frame 1 in every path that has an origin
    // avatar, which is what keeps the Hero in the tree for the flight. See
    // `initialClient` above.
    final client = clientAsync.valueOrNull ?? widget.initialClient;

    // The identity header renders as a dark plinth in BOTH light and dark app
    // themes (see _buildBody). Build that dark ThemeData once here so the header
    // wrap and the AppBar-over-header foreground share one instance rather than
    // each rebuilding a fromSeed ColorScheme.
    final darkTheme = AppTheme.dark;

    // Note the ordering: a *seeded* client wins over an error. If the refetch
    // fails but we already have the row the user tapped, showing that beats
    // an error page about data we're literally holding. The error only takes
    // over when there's nothing at all to render.
    final Widget body;
    if (client != null) {
      body = _buildBody(context, client, darkTheme);
    } else if (clientAsync.hasError) {
      body = AsyncErrorView(
        error: clientAsync.error!,
        onRetry: () =>
            ref.read(clientDetailProvider(widget.clientId).notifier).refresh(),
      );
    } else {
      body = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        // The header behind this bar is always dark, so the back button and
        // delete icon are pinned to the dark scheme's light onSurface — the
        // ambient onSurface would render near-black on the dark header in
        // light mode.
        foregroundColor: darkTheme.colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: _isDeleting ? null : _confirmDelete,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(client != null
              ? 'content'
              : clientAsync.hasError
                  ? 'error'
                  : 'loading'),
          child: body,
        ),
      ),
      floatingActionButton: client == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  context.push('/orders/new', extra: widget.clientId),
              icon: const Icon(Icons.add),
              label: const Text('New order'),
            ),
    );
  }

  Widget _buildBody(BuildContext context, Client client, ThemeData darkTheme) {
    final stats = ref.watch(clientStatsProvider(widget.clientId));
    // Ambient (light/dark) scheme for the lower content zone. The header
    // plinth above uses its own forced-dark scheme via a nested Theme.
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(clientDetailProvider(widget.clientId).notifier).refresh();
        // Orders section and the stats strip — plain FutureProviders with no
        // notifier, so refresh via invalidate rather than a .refresh() method.
        // The stats strip is where the guest count lives now that the embedded
        // guest section is gone (the roster has its own screen).
        ref.invalidate(clientOrdersProvider(widget.clientId));
        ref.invalidate(clientStatsProvider(widget.clientId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Identity header — always a dark plinth, in both light and dark
            // app themes (the target design keeps this region dark while the
            // content below follows the theme). Wrapping the subtree in the
            // dark ThemeData makes every scheme/token lookup inside — the name
            // text, the stats card surfaces, the quick-action circles — resolve
            // to its dark value without hand-recolouring each widget. A solid
            // dark base sits under the existing gradient so the gradient's
            // transparent tail fades to dark rather than to the light scaffold
            // behind it in light mode.
            Theme(
              data: darkTheme,
              child: Builder(
                builder: (context) {
                  final scheme = Theme.of(context).colorScheme;
                  return Container(
                    width: double.infinity,
                    color: scheme.surface,
                    child: Container(
                      width: double.infinity,
                      // Only the status-bar inset plus a small gap sits above
                      // the avatar — the avatar is centred, clear of the app
                      // bar's edge buttons, so it can tuck up beside them rather
                      // than reserving the full toolbar height below. Keeps the
                      // dark plinth under ~50% of the screen on small phones.
                      padding: EdgeInsets.fromLTRB(
                        24,
                        MediaQuery.of(context).padding.top + 12,
                        24,
                        22,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            scheme.primaryContainer.withOpacity(0.55),
                            scheme.surface.withOpacity(0),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 132,
                            height: 132,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Signature element: a measuring-tape ring around
                                // the avatar — a small nod to what this app is
                                // actually for (fittings and measurements), instead
                                // of a generic decorative halo.
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _MeasuringTapeRingPainter(
                                      color: scheme.primary,
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Hero(
                                    // Wraps the avatar only — NOT the enclosing
                                    // Stack. The camera-upload badge is pinned
                                    // inside that Stack, and it must stay put while
                                    // the photo flies.
                                    tag: clientPhotoHeroTag(widget.clientId),
                                    // MaterialRectArcTween (the MaterialApp
                                    // default) arcs the rect's two opposite corners
                                    // along *separate* circles. On a circle that
                                    // also grows 20px → 48px radius that reads as a
                                    // squash-and-wobble. The centre variant arcs
                                    // the centre point and scales width and height
                                    // uniformly — the circle stays a circle.
                                    //
                                    // This is the *destination* Hero on a push, and
                                    // the destination's tween is the one Flutter
                                    // consults (`toHero.createRectTween ??
                                    // controller.createRectTween`), so this governs
                                    // the inbound flight. The outbound (pop) flight
                                    // is governed by whichever Hero we're popping
                                    // back to — hence the same tween on the list
                                    // row and the order tile.
                                    createRectTween: (begin, end) =>
                                        MaterialRectCenterArcTween(
                                            begin: begin, end: end),
                                    // Without this the iOS back-swipe pops the
                                    // route with no flight at all — the avatar just
                                    // vanishes.
                                    transitionOnUserGestures: true,
                                    child: Material(
                                      color: Colors.transparent,
                                      shape: const CircleBorder(),
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        onTap: client.photoUrl == null
                                            ? null
                                            : () => showImageViewer(
                                                  context,
                                                  urls: [client.photoUrl!],
                                                  zoomable: false,
                                                ),
                                        child: CircleAvatar(
                                          radius: 48,
                                          // Neutral warm placeholder, matching
                                          // the app's other avatars/thumbnails
                                          // rather than a brand tint.
                                          backgroundColor:
                                              scheme.surfaceContainerHighest,
                                          backgroundImage: client.photoUrl !=
                                                  null
                                              ? NetworkImage(client.photoUrl!)
                                              : null,
                                          child: client.photoUrl == null
                                              ? Text(
                                                  client.name.isNotEmpty
                                                      ? client.name[0]
                                                          .toUpperCase()
                                                      : '?',
                                                  style: TextStyle(
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.w600,
                                                    color: context
                                                        .appTokens
                                                        .mutedForeground,
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 18,
                                  right: 18,
                                  child: GestureDetector(
                                    onTap: _isUploadingPhoto
                                        ? null
                                        : _pickAndUploadPhoto,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: scheme.surface,
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.15),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: scheme.primary,
                                        child: _isUploadingPhoto
                                            ? SizedBox(
                                                height: 14,
                                                width: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: scheme.onPrimary,
                                                ),
                                              )
                                            : Icon(Icons.camera_alt,
                                                size: 16,
                                                color: scheme.onPrimary),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            client.name,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 18),
                          _StatsCard(
                            stats: stats,
                            onRetry: () => ref.invalidate(
                                clientStatsProvider(widget.clientId)),
                            onViewGuests: () => context
                                .push('/clients/${widget.clientId}/guests'),
                          ),
                          // The client's note as a pull-quote, matching the
                          // order detail screen's treatment. Sits on the dark
                          // plinth (the wrapping Theme is dark), so the serif
                          // quote mark and body resolve to the dark palette.
                          if (client.notes != null &&
                              client.notes!.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: QuoteNote(text: client.notes!),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // The lower content zone sits on a lighter surface tier than the
            // dark header plinth above — `surfaceContainer` reads a clear step
            // lighter than the plinth's `surface` base in dark mode, so the two
            // regions stay visually distinct even when both are dark. In light
            // mode it's a slightly warmer cream beneath the dark header.
            Container(
              width: double.infinity,
              color: scheme.surfaceContainer,
              child: Padding(
                // Bottom padding clears the floating "New order" button even
                // when a client has little else on the page yet (no guests,
                // measurements, or orders) — the FAB floats at a fixed
                // Scaffold position regardless of content length.
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                child: Column(
                  children: [
                    _ContactCard(
                      client: client,
                      onEdit: () =>
                          context.push('/clients/${widget.clientId}/edit'),
                      onCall: () => _call(client.phone),
                      onWhatsapp: () => _whatsapp(client.phone),
                      onMessage: () => _sms(client.phone),
                      onEmail: client.email != null && client.email!.isNotEmpty
                          ? () => _email(client.email!)
                          : null,
                    ),
                    const SizedBox(height: 20),
                    MeasurementListSection(
                      recipient: clientRecipient(widget.clientId),
                    ),
                    const SizedBox(height: 20),
                    // Not wrapped in a _SectionCard: the Orders section renders
                    // full OrderCards (surfaceContainerLow), which would blend
                    // into a same-tier card and read as one cramped block. Left
                    // on the page background, the heading sits free and each
                    // card contrasts and breathes — matching the Orders tab.
                    ClientOrdersSection(clientId: widget.clientId),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Serif on the display family so the numerals read as the brand voice,
/// mirroring the Home dashboard cards. Falls back to a serif where Fraunces
/// isn't bundled.
TextStyle _statDisplay(BuildContext context, double size,
    {required Color color}) {
  final t = context.appTokens;
  return TextStyle(
    fontFamily: t.fontDisplay,
    fontFamilyFallback: t.fontDisplayFallback,
    fontSize: size,
    fontWeight: FontWeight.w500,
    color: color,
    height: 1.05,
  );
}

/// The revenue / active-orders / guests strip beneath the client's name.
/// Reads from [ClientStats] — currently a stub, see client_stats_provider.dart
/// — so the layout is already shaped for the real per-client stats endpoint.
///
/// Keeps its original two-column shape — Revenue on the left, Active orders and
/// Guests stacked on the right — but adopts the Home Task Overview card's three
/// traits: a dashed terracotta "running stitch" border ([StitchBorderPainter]),
/// the Fraunces display family on the figures, and a distinct tint per section
/// (terracotta / warm tan / neutral). Sits on the dark identity plinth, so its
/// scheme/token lookups resolve to the dark palette.
class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.stats,
    required this.onRetry,
    this.onViewGuests,
  });

  /// The async result of [clientStatsProvider]. Loading and error render
  /// inside the same painted shell as the data state so the card keeps its
  /// place and its terracotta stitch border across all three.
  final AsyncValue<ClientStats> stats;

  /// Re-fetches the stats — wired to the error state's retry affordance.
  final VoidCallback onRetry;

  /// Opens the client's full guest roster. When set, the Guests figure becomes
  /// tappable and grows a chevron; null leaves it as a plain stat.
  final VoidCallback? onViewGuests;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;

    return CustomPaint(
      // A dashed rounded border drawn over the card so the edge reads like a
      // terracotta running stitch — the same tailoring nod as the Home cards.
      foregroundPainter: StitchBorderPainter(
        color: scheme.primary.withOpacity(0.4),
        radius: tokens.radiusXl,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(tokens.radiusXl),
        ),
        clipBehavior: Clip.antiAlias,
        child: stats.when(
          // Keep the previous figures visible during a background refetch
          // (skipLoadingOnReload) so pull-to-refresh doesn't flash a spinner
          // over numbers that are already on screen.
          skipLoadingOnReload: true,
          loading: () => const SizedBox(
            height: 96,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: AsyncErrorView(
              error: err,
              compact: true,
              onRetry: () async => onRetry(),
            ),
          ),
          data: (data) => _statsContent(context, data),
        ),
      ),
    );
  }

  Widget _statsContent(BuildContext context, ClientStats stats) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    final divider = scheme.onSurface.withOpacity(0.07);

    return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left column: Revenue rides the brand terracotta — the headline.
              Expanded(
                flex: 5,
                child: Container(
                  color: scheme.primary.withOpacity(0.14),
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('REVENUE',
                          style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 0.6,
                              color: tokens.mutedForeground)),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(formatCompactNaira(stats.revenue),
                            style: _statDisplay(context, 28,
                                color: scheme.primary)),
                      ),
                      const SizedBox(height: 4),
                      if (stats.fullySettled)
                        Text('fully settled',
                            style: TextStyle(
                                fontSize: 11, color: tokens.mutedForeground))
                      else ...[
                        // What the client still owes us, in the warm tan chart
                        // tone — the same colour as the Active-orders figure.
                        if (stats.outstanding > 0)
                          _imbalanceLine(
                            context,
                            '${formatCompactNaira(stats.outstanding)} outstanding',
                            tokens.chart3,
                          ),
                        // What we owe back on overpaid orders. In the error tone
                        // so it reads as an action for the shop, not income.
                        // Both lines can show at once — one order underpaid,
                        // another overpaid — so it sits below outstanding.
                        if (stats.refundDue > 0) ...[
                          if (stats.outstanding > 0)
                            const SizedBox(height: 3),
                          _imbalanceLine(
                            context,
                            '${formatCompactNaira(stats.refundDue)} refund due',
                            scheme.error,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              Container(width: 1, color: divider),
              // Right column: two stacked rows, each in its own tint.
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    // Active orders in the warm tan chart tone.
                    Expanded(
                      child: _StatRow(
                        label: 'Active orders',
                        value: '${stats.activeOrders}',
                        tint: tokens.chart3.withOpacity(0.14),
                        valueColor: tokens.chart3,
                      ),
                    ),
                    Container(height: 1, color: divider),
                    // Guests stay neutral — and tap through to the roster.
                    Expanded(
                      child: _StatRow(
                        label: 'Guests',
                        value: '${stats.guests}',
                        tint: scheme.onSurface.withOpacity(0.05),
                        valueColor: tokens.mutedForeground,
                        onTap: onViewGuests,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
  }

  /// A small coloured dot + amount beneath the revenue figure, echoing the
  /// Home revenue card's OUTSTANDING line. Shared by the "outstanding" (client
  /// owes us) and "refund due" (we owe the client) lines, each in its own tint.
  Widget _imbalanceLine(BuildContext context, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ],
    );
  }
}

/// One tinted row in the stats strip's right column: a muted label with the
/// figure set in the display family, coloured to its section.
class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.tint,
    required this.valueColor,
    this.onTap,
  });

  final String label;
  final String value;
  final Color tint;
  final Color valueColor;

  /// When set, the whole row is tappable (ripple + a trailing chevron); when
  /// null it renders as a plain, static stat.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = context.appTokens.mutedForeground;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: muted)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: _statDisplay(context, 22, color: valueColor)),
              if (onTap != null) ...[
                const SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 18, color: muted),
              ],
            ],
          ),
        ],
      ),
    );

    // Tint rides on the Material (not an opaque Container above it) so the
    // InkWell ripple is visible over it.
    if (onTap == null) return Container(color: tint, child: row);
    return Material(
      color: tint,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

/// Groups phone / email / address / notes into a single elevated card
/// instead of four loose rows floating on the scaffold background.
class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.client,
    required this.onEdit,
    required this.onCall,
    required this.onWhatsapp,
    required this.onMessage,
    required this.onEmail,
  });

  final Client client;
  final VoidCallback onEdit;
  final VoidCallback onCall;
  final VoidCallback onWhatsapp;
  final VoidCallback onMessage;
  final VoidCallback? onEmail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final rows = <Widget>[
      _InfoRow(
        icon: Icons.phone_outlined,
        label: 'Phone',
        value: client.phone,
        accent: scheme.primary,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PhoneActionButton(
              icon: Icons.call_outlined,
              tooltip: 'Call',
              onTap: onCall,
            ),
            const SizedBox(width: 6),
            _PhoneActionButton(
              svgAsset: 'assets/icons/whatsapp.svg',
              // Official WhatsApp brand green.
              color: const Color(0xFF25D366),
              tooltip: 'WhatsApp',
              onTap: onWhatsapp,
            ),
            const SizedBox(width: 6),
            _PhoneActionButton(
              icon: Icons.forum_outlined,
              tooltip: 'Message',
              onTap: onMessage,
            ),
          ],
        ),
      ),
      if (client.email != null && client.email!.isNotEmpty)
        _InfoRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: client.email!,
          accent: scheme.tertiary,
          trailing: onEmail == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.open_in_new, size: 18),
                  onPressed: onEmail,
                  visualDensity: VisualDensity.compact,
                  color: context.appTokens.mutedForeground,
                ),
        ),
      if (client.address != null && client.address!.isNotEmpty)
        _InfoRow(
          icon: Icons.location_on_outlined,
          label: 'Address',
          value: client.address!,
          // `scheme.secondary` is a low-contrast *fill* tone (pale tan in light,
          // near-black brown in dark), so an icon painted in it all but
          // disappeared. chart4 is a distinct warm brown with contrast in both
          // themes.
          accent: context.appTokens.chart4,
        ),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 15),
      // Clip so the header's full-bleed `surface` fill and the edge-to-edge
      // dividers honour the rounded corners rather than poking past them.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        // Tighter corners than the other cards on this screen — matches the
        // Contact Details card in the target design, which reads a touch more
        // rectangular than the 20px plinth radius used elsewhere.
        borderRadius: BorderRadius.circular(14),
      ),
      // Outline in the card's own body tone (`surfaceContainerLow`), painted in
      // the FOREGROUND rather than the background decoration. A background
      // border sits behind the children, so the header's full-bleed `surface`
      // fill (and the body fill) paint over it along their edges — most visibly
      // swallowing the line at the rounded top-left/right corners. Drawing it on
      // top keeps the full 3px frame visible the whole way round.
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.surfaceContainerLow,
          width: 3,
        ),
      ),
      child: Column(
        children: [
          // Header band — a deliberately short strip on `surface`, a tone
          // recessed from the `surfaceContainerLow` body, so the title bar
          // reads as a lighter chrome above the raised contact rows. Its
          // vertical padding is smaller than the rows' (6 vs the 12 an
          // _InfoRow carries around a 36px icon), so it sits noticeably
          // shorter than the data lines below it.
          Container(
            width: double.infinity,
            // `surface` is the page-background tone, so this band reads as
            // "transparent" — it blends into the scaffold behind the card —
            // while staying a solid fill (no real transparency to composite).
            color: scheme.surface,
            // Top padding carries an extra 3px to clear the 3px foreground
            // outline, which paints over the content rather than reserving
            // layout space the way a background border would have.
            padding: const EdgeInsets.fromLTRB(16, 6, 8, 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CONTACT DETAILS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.appTokens.mutedForeground,
                        letterSpacing: 0.6,
                      ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    // Was 32 — dropped so the button stops setting the band's
                    // height, letting the reduced vertical padding make the
                    // header a compact strip well under the row height.
                    minimumSize: const Size(0, 22),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          // Body rows sit on the card's own `surfaceContainerLow`. Each row
          // carries the horizontal inset itself so the dividers between them
          // can run the full width of the card, matching the header divider.
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: rows[i],
            ),
            if (i != rows.length - 1)
              Divider(
                height: 1,
                color: scheme.outlineVariant.withOpacity(0.4),
              ),
          ],
        ],
      ),
    );
  }
}

/// Circular Call / WhatsApp / Message action on the phone row — the contact
/// actions worth surfacing inline, moved here from the header's quick-action
/// row. Pass either a Material [icon] or a bundled [svgAsset] (for the WhatsApp
/// brand glyph, which Material doesn't ship); the SVG is tinted to the same
/// `scheme.primary` as the Material icons so the three read as one set.
class _PhoneActionButton extends StatelessWidget {
  const _PhoneActionButton({
    this.icon,
    this.svgAsset,
    this.color,
    required this.tooltip,
    required this.onTap,
  }) : assert(icon != null || svgAsset != null,
            'Provide either an icon or an svgAsset');

  final IconData? icon;
  final String? svgAsset;

  /// Glyph + background tint. Defaults to `scheme.primary` so Call/Message
  /// match the card's accent; the WhatsApp button passes brand green.
  final Color? color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    final glyph = svgAsset != null
        ? SvgPicture.asset(
            svgAsset!,
            width: 17,
            height: 17,
            colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
          )
        : Icon(icon, size: 17, color: tint);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: tint.withOpacity(0.12),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Center(child: glyph),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.appTokens.mutedForeground,
                        letterSpacing: 0.6,
                      ),
                ),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _PhotoSourceTile extends StatelessWidget {
  const _PhotoSourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: scheme.onPrimaryContainer),
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}

/// Strips everything but digits from a phone number — `+233 20 112 3344` ->
/// `233201123344`. wa.me links require a bare international-format digit
/// string with no `+`, spaces, or dashes.
String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

/// Decorative ring of measuring-tape ticks behind the client's avatar.
/// Purely cosmetic — sits as a sibling to the Hero in the Stack, so it
/// never enters the flying subtree and has no bearing on the Hero flight.
class _MeasuringTapeRingPainter extends CustomPainter {
  const _MeasuringTapeRingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final tickPaint = Paint()
      ..color = color.withOpacity(0.35)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    const tickCount = 60;
    for (var i = 0; i < tickCount; i++) {
      final angle = (2 * math.pi / tickCount) * i;
      final isMajor = i % 5 == 0;
      final tickLength = isMajor ? 8.0 : 4.0;
      final outer = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final inner = Offset(
        center.dx + (radius - tickLength) * math.cos(angle),
        center.dy + (radius - tickLength) * math.sin(angle),
      );
      canvas.drawLine(
        inner,
        outer,
        isMajor
            ? (tickPaint..color = color.withOpacity(0.55))
            : (tickPaint..color = color.withOpacity(0.25)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MeasuringTapeRingPainter oldDelegate) =>
      oldDelegate.color != color;
}
