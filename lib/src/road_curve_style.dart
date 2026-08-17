import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'road_waypoint.dart';
import 'roadmap_geometry.dart';

/// Strategy that turns a [RoadmapGeometry]'s parameters into an actual [Path].
///
/// Implementations work in normalized *progress* space: `t` runs 0.0 at the
/// road's start to 1.0 at its end, and `cross` runs 0.0-1.0 across the road's
/// width (0.5 being center). [RoadmapGeometry.mapProgress] turns those into
/// pixels, applying orientation and the road's
/// [RoadmapGeometry.alongStart]/[RoadmapGeometry.alongEnd] extent.
///
/// Because everything is a fraction of the road's own extent, a curve always
/// spans exactly the extent the user asked for, however many turns it makes.
///
/// Subclasses must implement `==`/`hashCode` — geometry is compared to decide
/// whether the path must be rebuilt, so a style that still compares equal
/// after its parameters changed will render stale.
abstract class RoadCurveStyle {
  /// Abstract const constructor for subclasses.
  const RoadCurveStyle();

  /// Builds the road path for the given canvas [size] under [geometry].
  Path build(Size size, RoadmapGeometry geometry);

  /// How many segments this shape has, used to size the road under
  /// `RoadmapSizing.fixedSegmentExtent`. Defaults to
  /// [RoadmapGeometry.curveCount]; shapes that define their own segments
  /// should override it so length follows the real shape.
  int segmentCount(RoadmapGeometry geometry) => geometry.curveCount;
}

/// Winding S-curve road: swings smoothly out to one side, back to center, out
/// to the other side, and back, [RoadmapGeometry.curveCount] times over the
/// road's full extent.
class SCurveStyle extends RoadCurveStyle {
  /// Creates a winding S-curve shape.
  const SCurveStyle();

  @override
  Path build(Size size, RoadmapGeometry geometry) {
    final int n = geometry.curveCount;
    final double leftCross = 0.5 + geometry.curveAmplitude;
    final double rightCross = 0.5 - geometry.curveAmplitude;
    // Each full S consumes 1/n of the road; each half-swing, half of that.
    final double w = 1.0 / (2 * n);

    final start = geometry.mapProgress(0.0, rightCross, size);
    final path = Path()..moveTo(start.dx, start.dy);

    double t = 0.0;
    for (int i = 0; i < n; i++) {
      _swing(path, geometry, size, leftCross, t, w);
      t += w;
      _swing(path, geometry, size, rightCross, t, w);
      t += w;
    }
    return path;
  }

  void _swing(
    Path path,
    RoadmapGeometry geometry,
    Size size,
    double sideCross,
    double t0,
    double w,
  ) {
    final c1 = geometry.mapProgress(t0, sideCross, size);
    final e1 = geometry.mapProgress(t0 + w * 0.5, sideCross, size);
    path.quadraticBezierTo(c1.dx, c1.dy, e1.dx, e1.dy);

    final c2 = geometry.mapProgress(t0 + w, sideCross, size);
    final e2 = geometry.mapProgress(t0 + w, 0.5, size);
    path.quadraticBezierTo(c2.dx, c2.dy, e2.dx, e2.dy);
  }

  @override
  bool operator ==(Object other) => other is SCurveStyle;

  @override
  int get hashCode => (SCurveStyle).hashCode;
}

/// Same winding schedule as [SCurveStyle] but joined with straight segments,
/// producing sharp angular turns.
class ZigzagCurveStyle extends RoadCurveStyle {
  /// Creates an angular zigzag shape.
  const ZigzagCurveStyle();

  @override
  Path build(Size size, RoadmapGeometry geometry) {
    final int n = geometry.curveCount;
    final double leftCross = 0.5 + geometry.curveAmplitude;
    final double rightCross = 0.5 - geometry.curveAmplitude;
    final double w = 1.0 / (2 * n);

    final start = geometry.mapProgress(0.0, rightCross, size);
    final path = Path()..moveTo(start.dx, start.dy);

    double t = 0.0;
    for (int i = 0; i < n; i++) {
      _peak(path, geometry, size, leftCross, t, w);
      t += w;
      _peak(path, geometry, size, rightCross, t, w);
      t += w;
    }
    return path;
  }

  void _peak(
    Path path,
    RoadmapGeometry geometry,
    Size size,
    double sideCross,
    double t0,
    double w,
  ) {
    final peak = geometry.mapProgress(t0 + w * 0.5, sideCross, size);
    final centre = geometry.mapProgress(t0 + w, 0.5, size);
    path.lineTo(peak.dx, peak.dy);
    path.lineTo(centre.dx, centre.dy);
  }

  @override
  bool operator ==(Object other) => other is ZigzagCurveStyle;

  @override
  int get hashCode => (ZigzagCurveStyle).hashCode;
}

/// A continuous sine wave spanning the road's extent, with amplitude
/// [RoadmapGeometry.curveAmplitude] and [RoadmapGeometry.curveCount] full
/// oscillations.
///
/// Drawn as cubic segments (four per oscillation) rather than sampled line
/// segments, so it stays smooth at any size.
class SineCurveStyle extends RoadCurveStyle {
  /// Creates a smooth sine-wave shape.
  const SineCurveStyle();

  @override
  Path build(Size size, RoadmapGeometry geometry) {
    final int quarters = math.max(1, geometry.curveCount * 4);
    final double step = 1.0 / quarters;

    Offset at(double t) => geometry.mapProgress(t, _cross(geometry, t), size);

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (int i = 0; i < quarters; i++) {
      final double t0 = i * step;
      final double t1 = t0 + step;
      // Solve for the control points of a cubic that interpolates the true
      // sine at u = 0, 1/3, 2/3 and 1 of this quarter-wave, rather than
      // using on-curve points as controls (which visibly undershoots the
      // peaks). Keeps every oscillation within a fraction of a pixel.
      final Offset p0 = at(t0);
      final Offset p3 = at(t1);
      final Offset q1 = at(t0 + step / 3);
      final Offset q2 = at(t0 + step * 2 / 3);
      final Offset c1 = (p0 * -5 + q1 * 18 - q2 * 9 + p3 * 2) / 6;
      final Offset c2 = (p0 * 2 - q1 * 9 + q2 * 18 + p3 * -5) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p3.dx, p3.dy);
    }
    return path;
  }

  double _cross(RoadmapGeometry geometry, double t) =>
      0.5 +
      geometry.curveAmplitude * math.sin(2 * math.pi * geometry.curveCount * t);

  @override
  bool operator ==(Object other) => other is SineCurveStyle;

  @override
  int get hashCode => (SineCurveStyle).hashCode;
}

/// A single straight segment spanning the road's extent, ignoring
/// [RoadmapGeometry.curveCount] and [RoadmapGeometry.curveAmplitude]. Useful
/// as a plain timeline/progress line rather than a winding road.
class StraightCurveStyle extends RoadCurveStyle {
  /// Creates a straight-line shape.
  const StraightCurveStyle();

  @override
  Path build(Size size, RoadmapGeometry geometry) {
    final start = geometry.mapProgress(0.0, 0.5, size);
    final end = geometry.mapProgress(1.0, 0.5, size);
    return Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);
  }

  @override
  int segmentCount(RoadmapGeometry geometry) => 1;

  @override
  bool operator ==(Object other) => other is StraightCurveStyle;

  @override
  int get hashCode => (StraightCurveStyle).hashCode;
}

/// Full manual control over the road's shape: you place every turn.
///
/// Ignores [RoadmapGeometry.curveCount]/[RoadmapGeometry.curveAmplitude]
/// entirely — each [RoadWaypoint.cross] says how far that turn swings, each
/// [RoadWaypoint.at] (or automatic even spacing) says where along the road it
/// sits, and [RoadWaypoint.turn] picks smooth or sharp.
///
/// ```dart
/// WaypointCurveStyle([
///   RoadWaypoint(cross: 0.2),
///   RoadWaypoint(cross: 0.8),
///   RoadWaypoint(cross: 0.5, turn: RoadTurnType.sharp),
///   RoadWaypoint(cross: 0.9),
/// ])
/// ```
class WaypointCurveStyle extends RoadCurveStyle {
  /// Creates a road shaped by the given [waypoints], start to end.
  const WaypointCurveStyle(this.waypoints);

  /// The turns, ordered from the start of the road to its end.
  final List<RoadWaypoint> waypoints;

  @override
  Path build(Size size, RoadmapGeometry geometry) {
    assert(
      waypoints.length >= 2,
      'WaypointCurveStyle needs at least 2 waypoints, got ${waypoints.length}',
    );
    final int n = waypoints.length;
    final List<Offset> points = List.generate(n, (i) {
      final RoadWaypoint wp = waypoints[i];
      return geometry.mapProgress(wp.at ?? i / (n - 1), wp.cross, size);
    });

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < n - 1; i++) {
      final Offset point = points[i];
      if (waypoints[i].turn == RoadTurnType.sharp) {
        path.lineTo(point.dx, point.dy);
      } else {
        final Offset end = Offset.lerp(point, points[i + 1], 0.5)!;
        path.quadraticBezierTo(point.dx, point.dy, end.dx, end.dy);
      }
    }
    final Offset last = points[n - 1];
    path.lineTo(last.dx, last.dy);
    return path;
  }

  /// One segment between each pair of waypoints — so a waypoint road sized
  /// with `RoadmapSizing.fixedSegmentExtent` grows with the turns you
  /// actually placed, not with `curveCount`.
  @override
  int segmentCount(RoadmapGeometry geometry) =>
      math.max(1, waypoints.length - 1);

  @override
  bool operator ==(Object other) =>
      other is WaypointCurveStyle && listEquals(other.waypoints, waypoints);

  @override
  int get hashCode =>
      Object.hash(WaypointCurveStyle, Object.hashAll(waypoints));
}

/// Ultimate escape hatch: builds the road path however you like, given the
/// canvas [Size] and the resolved [RoadmapGeometry]. Bypasses every other
/// curve parameter — you own the geometry completely.
///
/// Two instances compare equal when they share the same [builder], so hoist
/// the function to a field or top-level function; an inline closure allocates
/// a new function every build and rebuilds the path each time.
class CustomCurveStyle extends RoadCurveStyle {
  /// Creates a road whose [Path] is produced entirely by [builder].
  const CustomCurveStyle(this.builder, {this.segments});

  /// Builds the path. Prefer [RoadmapGeometry.mapProgress] for coordinates so
  /// the result honors orientation and the road's extent.
  final Path Function(Size size, RoadmapGeometry geometry) builder;

  /// Segment count reported for `RoadmapSizing.fixedSegmentExtent`. Falls
  /// back to [RoadmapGeometry.curveCount] when null.
  final int? segments;

  @override
  Path build(Size size, RoadmapGeometry geometry) => builder(size, geometry);

  @override
  int segmentCount(RoadmapGeometry geometry) => segments ?? geometry.curveCount;

  @override
  bool operator ==(Object other) =>
      other is CustomCurveStyle &&
      other.builder == builder &&
      other.segments == segments;

  @override
  int get hashCode => Object.hash(CustomCurveStyle, builder, segments);
}
