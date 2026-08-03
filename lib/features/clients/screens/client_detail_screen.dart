import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tailored_business_app/features/guests/state/guest_list_notifier.dart';

import '../../guests/widgets/guest_list_section.dart';
import '../../measurements/models/recipient_ref.dart';
import '../../measurements/widgets/measurement_list_section.dart';
import '../../orders/state/client_orders_providers.dart';
import '../../orders/widgets/client_orders_section.dart';
import '../models/client.dart';
import '../data/client_repository.dart';
import '../state/client_detail_notifier.dart';
import '../state/client_list_notifier.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/utils/hero_tags.dart';

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

  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(clientDetailProvider(widget.clientId));

    // Prefer live data; fall back to whatever the caller handed us. The point
    // is that this is non-null on frame 1 in every path that has an origin
    // avatar, which is what keeps the Hero in the tree for the flight. See
    // `initialClient` above.
    final client = clientAsync.valueOrNull ?? widget.initialClient;

    // Note the ordering: a *seeded* client wins over an error. If the refetch
    // fails but we already have the row the user tapped, showing that beats
    // an error page about data we're literally holding. The error only takes
    // over when there's nothing at all to render.
    final Widget body;
    if (client != null) {
      body = _buildBody(context, client);
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
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => context.push('/clients/${widget.clientId}/edit'),
          ),
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
    );
  }

  Widget _buildBody(BuildContext context, Client client) {
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait<void>([
          ref.read(clientDetailProvider(widget.clientId).notifier).refresh(),
          ref.read(guestListProvider(widget.clientId).notifier).refresh(),
        ]);
        // Orders section — a plain FutureProvider.family with no notifier,
        // so refresh via invalidate rather than a .refresh() method.
        ref.invalidate(clientOrdersProvider(widget.clientId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Identity header — a quiet gradient plinth that gives the
            // avatar somewhere to sit, rather than dropping it straight
            // onto the scaffold background.
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + kToolbarHeight + 12,
                24,
                28,
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
                                  backgroundColor: scheme.primaryContainer,
                                  backgroundImage: client.photoUrl != null
                                      ? NetworkImage(client.photoUrl!)
                                      : null,
                                  child: client.photoUrl == null
                                      ? Text(
                                          client.name.isNotEmpty
                                              ? client.name[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w600,
                                            color: scheme.onPrimaryContainer,
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
                            onTap:
                                _isUploadingPhoto ? null : _pickAndUploadPhoto,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: scheme.surface,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
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
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: scheme.onPrimary,
                                        ),
                                      )
                                    : Icon(Icons.camera_alt,
                                        size: 16, color: scheme.onPrimary),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    client.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                children: [
                  _ContactCard(client: client),
                  const SizedBox(height: 20),
                  _SectionCard(
                    child: GuestListSection(clientId: widget.clientId),
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    child: MeasurementListSection(
                      recipient: clientRecipient(widget.clientId),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    child: ClientOrdersSection(clientId: widget.clientId),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A quiet elevated surface for a section widget (Guests / Measurements /
/// Orders). Each of those already renders its own title, icon, and action
/// button internally — this just gives that content somewhere to sit
/// instead of floating loose on the scaffold background, matching
/// `_ContactCard` above so the whole page reads as one family of cards.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: child,
    );
  }
}

/// Groups phone / email / address / notes into a single elevated card
/// instead of four loose rows floating on the scaffold background.
class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final rows = <Widget>[
      _InfoRow(
        icon: Icons.phone_outlined,
        label: 'Phone',
        value: client.phone,
        accent: scheme.primary,
      ),
      if (client.email != null && client.email!.isNotEmpty)
        _InfoRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: client.email!,
          accent: scheme.tertiary,
        ),
      if (client.address != null && client.address!.isNotEmpty)
        _InfoRow(
          icon: Icons.location_on_outlined,
          label: 'Address',
          value: client.address!,
          accent: scheme.secondary,
        ),
      if (client.notes != null && client.notes!.isNotEmpty)
        _InfoRow(
          icon: Icons.notes_outlined,
          label: 'Notes',
          value: client.notes!,
          accent: scheme.primary,
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

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
                        color: Theme.of(context).colorScheme.outline,
                        letterSpacing: 0.6,
                      ),
                ),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
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
