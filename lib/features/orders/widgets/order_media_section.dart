import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/pick_image.dart';
import '../models/order_media.dart';
import '../state/order_detail_notifier.dart';

import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/image_viewer.dart';
/// The order-level media strip on the detail screen: up to 3 photos of the
/// whole job, each removable, with an "add" tile while under the cap. Drives
/// OrderDetailNotifier.addMedia / deleteMedia. Owns its own busy flag so the
/// rest of the screen stays interactive during an upload.
class OrderMediaSection extends ConsumerStatefulWidget {
  const OrderMediaSection({
    super.key,
    required this.orderId,
    required this.media,
    required this.canAdd,
    required this.enabled,
  });

  final String orderId;
  final List<OrderMedia> media;

  /// Backend caps media at 3 — hide the add tile once full.
  final bool canAdd;

  /// False when the order is delivered/cancelled (locked): show the media
  /// read-only, no add/remove.
  final bool enabled;

  @override
  ConsumerState<OrderMediaSection> createState() => _OrderMediaSectionState();
}

class _OrderMediaSectionState extends ConsumerState<OrderMediaSection> {
  bool _busy = false;

  Future<void> _add() async {
    final file = await pickImageFile(context);
    if (file == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(orderDetailProvider(widget.orderId).notifier)
          .addMedia(file);
      if (mounted) showSuccessSnackbar(context, 'Media added');
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Could not add media');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(OrderMedia item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this media?'),
        content: const Text('It will be deleted from the order.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(orderDetailProvider(widget.orderId).notifier)
          .deleteMedia(item.id);
      if (mounted) showSuccessSnackbar(context, 'Media removed');
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Could not remove media');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showAdd = widget.enabled && widget.canAdd;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Media', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(width: 8),
            Text(
              '${widget.media.length}/3',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            if (_busy) ...[
              const SizedBox(width: 8),
              const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (widget.media.isEmpty && !showAdd)
          Text(
            'No media',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < widget.media.length; i++)
                _MediaThumb(
                  media: widget.media[i],
                  // Collect all image URLs from the media list so tapping
                  // one opens the whole gallery, letting the user swipe
                  // through — videos are excluded because the viewer only
                  // knows how to handle images.
                  imageUrls: [
                    for (final m in widget.media)
                      if (m.fileType != 'video') m.fileUrl,
                  ],
                  imageIndex: [
                    for (final m in widget.media)
                      if (m.fileType != 'video') m,
                  ].indexOf(widget.media[i]),
                  onRemove:
                      widget.enabled && !_busy ? () => _remove(widget.media[i]) : null,
                ),
              if (showAdd)
                _AddTile(onTap: _busy ? null : _add),
            ],
          ),
      ],
    );
  }
}

class _MediaThumb extends StatelessWidget {
  const _MediaThumb({
    required this.media,
    required this.imageUrls,
    required this.imageIndex,
    this.onRemove,
  });

  final OrderMedia media;

  /// All image URLs in the parent media list — passed so the viewer can
  /// present them as a swipeable gallery starting on the tapped image.
  /// Videos are excluded upstream because the viewer only handles images.
  final List<String> imageUrls;

  /// This item's position within [imageUrls]. -1 if this thumb is a video
  /// (no image to open) — tap is a no-op in that case.
  final int imageIndex;

  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isVideo = media.fileType == 'video';
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: isVideo || imageIndex < 0
                ? null
                : () => showImageViewer(
                      context,
                      urls: imageUrls,
                      initialIndex: imageIndex,
                    ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isVideo
                  ? Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.play_circle_outline, size: 28),
                    )
                  : Image.network(
                      media.fileUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: const Icon(Icons.broken_image_outlined, size: 24),
                      ),
                    ),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: -6,
              right: -6,
              child: IconButton(
                visualDensity: VisualDensity.compact,
                icon: CircleAvatar(
                  radius: 11,
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                onPressed: onRemove,
              ),
            ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: const Icon(Icons.add_a_photo_outlined),
      ),
    );
  }
}
