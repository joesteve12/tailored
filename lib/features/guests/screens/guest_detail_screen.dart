import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../measurements/models/recipient_ref.dart';
import '../../measurements/widgets/measurement_list_section.dart';
import '../data/guest_repository.dart';
import '../state/guest_detail_notifier.dart';
import '../state/guest_list_notifier.dart';
import '../../../core/widgets/async_error_view.dart';

import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/image_viewer.dart';
class GuestDetailScreen extends ConsumerStatefulWidget {
  const GuestDetailScreen({
    super.key,
    required this.clientId,
    required this.guestId,
  });

  final String clientId;
  final String guestId;

  @override
  ConsumerState<GuestDetailScreen> createState() => _GuestDetailScreenState();
}

class _GuestDetailScreenState extends ConsumerState<GuestDetailScreen> {
  bool _isUploadingPhoto = false;
  bool _isDeleting = false;

  GuestDetailArg get _key =>
      (clientId: widget.clientId, guestId: widget.guestId);

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
          .read(guestRepositoryProvider)
          .uploadPhoto(widget.guestId, File(picked.path));
      // Same refetch-as-test pattern as ClientDetailScreen — if photoUrl
      // is still null after this, the upload endpoint isn't persisting
      // it onto the guest record server-side, and uploadPhoto's
      // GuestRepository return value would need a follow-up update()
      // call instead.
      await ref.read(guestDetailProvider(_key).notifier).refresh();
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
        title: const Text('Delete guest?'),
        content: const Text(
          'This cannot be undone. (Note: deleting a client cascades to '
          'that client\'s measurements — confirmed. Whether deleting a '
          'guest does the same to that guest\'s own measurement history, '
          'or leaves it orphaned, hasn\'t been checked.)',
        ),
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
      await ref
          .read(guestRepositoryProvider)
          .delete(widget.clientId, widget.guestId);
      await ref.read(guestListProvider(widget.clientId).notifier).refresh();
      if (mounted) {
        showSuccessSnackbar(context, 'Guest deleted');
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
    final guestAsync = ref.watch(guestDetailProvider(_key));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guest'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => context.push(
              '/clients/${widget.clientId}/guests/${widget.guestId}/edit',
            ),
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
      body: guestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncErrorView(
          error: err,
          onRetry: () => ref.read(guestDetailProvider(_key).notifier).refresh(),
        ),
        data: (guest) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: guest.photoUrl == null
                        ? null
                        : () => showImageViewer(
                              context,
                              urls: [guest.photoUrl!],
                              zoomable: false,
                            ),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundImage: guest.photoUrl != null
                          ? NetworkImage(guest.photoUrl!)
                          : null,
                      child: guest.photoUrl == null
                          ? Text(
                              guest.name.isNotEmpty
                                  ? guest.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 32),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).colorScheme.primary,
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
              Text(guest.name, style: Theme.of(context).textTheme.headlineSmall),
              if (guest.relation != null && guest.relation!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    guest.relation!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              MeasurementListSection(recipient: guestRecipient(guest.id)),
            ],
          ),
        ),
      ),
    );
  }
}
