import 'package:flutter/material.dart';

/// Strokes a dashed rounded rectangle so a card's edge reads like a hand-sewn
/// running stitch — a tailoring nod used on the Home task-overview card and the
/// client-detail stats card.
///
/// Flutter's [Border] can't draw dashes, so we walk the rounded-rect path and
/// lay down short dashes by hand. Hand it to a [CustomPaint.foregroundPainter]
/// so the stitch sits on top of the card's fill.
class StitchBorderPainter extends CustomPainter {
  const StitchBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double strokeWidth = 1.4;
  static const double dashLength = 8;
  static const double gapLength = 6;
  // How far the stitch line is pulled in from the card's edge.
  static const double inset = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Pull the stitch line in from the card edge on all sides.
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(
            inset, inset, size.width - inset * 2, size.height - inset * 2),
        Radius.circular((radius - inset).clamp(0, radius)),
      ));

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(StitchBorderPainter old) =>
      old.color != color || old.radius != radius;
}
