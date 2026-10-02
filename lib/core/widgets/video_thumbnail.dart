import 'package:flutter/material.dart';

/// ImageKit generates a still poster frame from a video when you append
/// `/ik-thumbnail.jpg` to the video's URL — so a video gets a real preview with
/// a plain [Image.network], no client-side video decoding. Any existing `?tr=`
/// query is preserved after the thumbnail segment.
String imagekitVideoThumbnailUrl(String videoUrl) {
  final q = videoUrl.indexOf('?');
  if (q == -1) return '$videoUrl/ik-thumbnail.jpg';
  return '${videoUrl.substring(0, q)}/ik-thumbnail.jpg${videoUrl.substring(q)}';
}

/// A video preview tile: the ImageKit poster frame with a play badge over it so
/// it reads as a video at a glance. Fills its parent — wrap in a [ClipRRect] for
/// rounding, as the media/style strips already do. Falls back to a plain tinted
/// surface (the badge still marks it as video) if the poster can't load.
class VideoThumbnail extends StatelessWidget {
  const VideoThumbnail({
    super.key,
    required this.url,
    this.badgeSize = 26,
  });

  final String url;
  final double badgeSize;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imagekitVideoThumbnailUrl(url),
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : fallback,
          errorBuilder: (_, __, ___) => fallback,
        ),
        Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.38),
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(badgeSize * 0.18),
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: badgeSize,
            ),
          ),
        ),
      ],
    );
  }
}
