import 'dart:io';

import 'package:flutter/material.dart';
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
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
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
      if (mounted) showSuccessSnackbar(context, 'Photo uploaded');
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Photo upload failed');
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete client?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

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
      appBar: AppBar(
        title: const Text('Client'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
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
      body: body,
    );
  }

  Widget _buildBody(BuildContext context, Client client) {
    return RefreshIndicator(
          onRefresh: () async {
            await Future.wait<void>([
              ref
                  .read(clientDetailProvider(widget.clientId).notifier)
                  .refresh(),
              ref.read(guestListProvider(widget.clientId).notifier).refresh(),
            ]);
            // Orders section — a plain FutureProvider.family with no notifier,
            // so refresh via invalidate rather than a .refresh() method.
            ref.invalidate(clientOrdersProvider(widget.clientId));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: client.photoUrl == null
                          ? null
                          : () => showImageViewer(
                                context,
                                urls: [client.photoUrl!],
                                zoomable: false,
                              ),
                      child: Hero(
                        // Wraps the avatar only — NOT the enclosing Stack. The
                        // camera-upload badge is pinned inside that Stack, and
                        // it must stay put while the photo flies.
                        tag: clientPhotoHeroTag(widget.clientId),
                        // MaterialRectArcTween (the MaterialApp default) arcs
                        // the rect's two opposite corners along *separate*
                        // circles. On a circle that also grows 20px → 48px
                        // radius that reads as a squash-and-wobble. The centre
                        // variant arcs the centre point and scales width and
                        // height uniformly — the circle stays a circle.
                        //
                        // This is the *destination* Hero on a push, and the
                        // destination's tween is the one Flutter consults
                        // (`toHero.createRectTween ?? controller.createRectTween`),
                        // so this governs the inbound flight. The outbound
                        // (pop) flight is governed by whichever Hero we're
                        // popping back to — hence the same tween on the list
                        // row and the order tile.
                        createRectTween: (begin, end) =>
                            MaterialRectCenterArcTween(begin: begin, end: end),
                        // Without this the iOS back-swipe pops the route with
                        // no flight at all — the avatar just vanishes.
                        transitionOnUserGestures: true,
                        child: CircleAvatar(
                          radius: 48,
                          backgroundImage: client.photoUrl != null
                              ? NetworkImage(client.photoUrl!)
                              : null,
                          child: client.photoUrl == null
                              ? Text(
                                  client.name.isNotEmpty
                                      ? client.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(fontSize: 32),
                                )
                              : null,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: _isUploadingPhoto
                              ? const SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.camera_alt,
                                  size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(client.name,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                _InfoRow(
                    icon: Icons.phone, label: 'Phone', value: client.phone),
                if (client.email != null && client.email!.isNotEmpty)
                  _InfoRow(
                      icon: Icons.email, label: 'Email', value: client.email!),
                if (client.address != null && client.address!.isNotEmpty)
                  _InfoRow(
                      icon: Icons.location_on,
                      label: 'Address',
                      value: client.address!),
                if (client.notes != null && client.notes!.isNotEmpty)
                  _InfoRow(
                      icon: Icons.notes, label: 'Notes', value: client.notes!),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                GuestListSection(clientId: widget.clientId),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                MeasurementListSection(
                  recipient: clientRecipient(widget.clientId),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                ClientOrdersSection(clientId: widget.clientId),
              ],
            ),
          ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        )),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
