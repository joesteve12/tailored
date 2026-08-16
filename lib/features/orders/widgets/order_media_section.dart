import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
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
                    color: context.appTokens.mutedForeground,
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
        const SizedBox(height: 12),
        if (widget.media.isEmpty && !showAdd)
          Text(
            'No media',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.appTokens.mutedForeground,
                ),
          )
        else ...[
          if (widget.media.isNotEmpty)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
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
                    onRemove: widget.enabled && !_busy
                        ? () => _remove(widget.media[i])
                        : null,
                  ),
              ],
            ),
          if (showAdd) ...[
            if (widget.media.isNotEmpty) const SizedBox(height: 12),
            _AddTile(onTap: _busy ? null : _add),
          ],
        ],
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
    final t = context.appTokens;
    final isVideo = media.fileType == 'video';
    final placeholder = Container(
      color: t.sidebarAccent,
      alignment: Alignment.center,
      child: Icon(
        isVideo ? Icons.play_circle_outline : Icons.image_outlined,
        size: 28,
        color: t.sidebarForeground.withValues(alpha: 0.35),
      ),
    );
    return Stack(
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
            borderRadius: BorderRadius.circular(t.radiusLg),
            child: isVideo
                ? placeholder
                : Image.network(
                    media.fileUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) =>
                        progress == null ? child : placeholder,
                    errorBuilder: (_, __, ___) => Container(
                      color: t.sidebarAccent,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 24,
                        color: t.sidebarForeground.withValues(alpha: 0.35),
                      ),
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
    );
  }
}

/// Full-width dashed dropzone, styled after the app's warm sidebar palette:
/// a camera icon over a label, inside a dashed rounded-rect border rather
/// than the solid one used elsewhere, so it reads as "drop something here"
/// instead of just another filled tile.
class _AddTile extends StatelessWidget {
  const _AddTile({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final borderRadius = BorderRadius.circular(t.radiusLg);
    final foreground = t.sidebarForeground.withValues(alpha: 0.55);
    return InkWell(
      borderRadius: borderRadius,
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: t.sidebarForeground.withValues(alpha: 0.35),
          borderRadius: borderRadius,
        ),
        child: Container(
          width: double.infinity,
          height: 96,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt_outlined, color: foreground),
              const SizedBox(height: 4),
              Text(
                'Add photo',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: foreground,
                      fontWeight: t.fontWeightMedium,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashes a rounded-rect border by walking the path's arc length in on/off
/// segments — Flutter has no built-in dashed [BoxDecoration], and this is a
/// small enough shape not to warrant a package dependency.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.borderRadius});

  final Color color;
  final BorderRadius borderRadius;

  static const double _dashWidth = 6;
  static const double _dashGap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = borderRadius.toRRect(Offset.zero & size);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderRadius != borderRadius;
}
