import 'package:flutter/material.dart';

import 'curved_roadmap_style.dart';
import 'road_path.dart';

double _clamp(double v, double lo, double hi) =>
    v < lo ? lo : (v > hi ? hi : v);

/// Paints a prebuilt [RoadPath] with [style].
///
/// Takes the path rather than building one: [CurvedRoadmap] builds it once
/// per (size, geometry) and shares it with marker positioning, so an
/// animating road doesn't rebuild beziers and recompute path metrics on
/// every frame.
class CurvedRoadmapPainter extends CustomPainter {
  /// Paints [roadPath] using [style].
  const CurvedRoadmapPainter({
    required this.roadPath,
    required this.style,
    required this.completedColor,
    this.progress,
    this.revealFraction = 1.0,
  });

  /// Prebuilt road geometry.
  final RoadPath roadPath;

  /// Paint configuration.
  final CurvedRoadmapStyle style;

  /// Resolved color for the completed portion (theme fallback applied).
  final Color completedColor;

  /// Fraction of the road painted as completed, or null for none.
  final double? progress;

  /// Fraction of the road drawn at all, for the draw-in animation.
  final double revealFraction;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || roadPath.length <= 0) return;

    final double total = roadPath.length;
    final double revealLength = total * _clamp(revealFraction, 0.0, 1.0);
    if (revealLength <= 0) return;
    final double? progressLength =
        progress == null ? null : total * _clamp(progress!, 0.0, 1.0);

    final Paint roadPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.roadWidth
      ..strokeCap = StrokeCap.round;
    if (style.roadGradient != null) {
      roadPaint.shader = style.roadGradient!.createShader(
        roadPath.path.getBounds(),
      );
    } else {
      roadPaint.color = style.roadColor;
    }

    if (progressLength != null) {
      final double done = _clamp(progressLength, 0.0, revealLength);
      if (done > 0) {
        canvas.drawPath(
          roadPath.extract(0, done),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = style.roadWidth
            ..strokeCap = StrokeCap.round
            ..color = completedColor,
        );
      }
      if (revealLength > done) {
        canvas.drawPath(roadPath.extract(done, revealLength), roadPaint);
      }
    } else {
      canvas.drawPath(roadPath.extract(0, revealLength), roadPaint);
    }

    if (style.lineStyle != RoadLineStyle.none) {
      final Paint linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.roadWidth / 10
        ..color = style.lineColor;
      final Path line = style.lineStyle == RoadLineStyle.solid
          ? roadPath.extract(0, revealLength)
          : roadPath.dashed(
              dashWidth: style.dashWidth,
              dashSpace: style.dashSpace,
              upTo: revealLength,
            );
      canvas.drawPath(line, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CurvedRoadmapPainter oldDelegate) {
    return !identical(oldDelegate.roadPath, roadPath) ||
        oldDelegate.style != style ||
        oldDelegate.completedColor != completedColor ||
        oldDelegate.progress != progress ||
        oldDelegate.revealFraction != revealFraction;
  }
}
