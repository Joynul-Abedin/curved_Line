import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'road_curve_style.dart';

/// Axis the road winds along.
enum RoadmapOrientation {
  /// Road winds vertically.
  vertical,

  /// Road winds horizontally.
  horizontal,
}

/// The road's *shape*: which curve it follows, how many turns it makes, how
/// far they swing, and where along its box the road starts and ends.
///
/// Kept separate from [CurvedRoadmapStyle] (which is purely paint) so that
/// theming colors never drags layout geometry along with it.
///
/// To draw the road backwards, swap [alongStart] and [alongEnd]:
/// ```dart
/// const RoadmapGeometry(alongStart: 0.05, alongEnd: 0.95) // top to bottom
/// ```
@immutable
class RoadmapGeometry {
  /// Creates road geometry.
  const RoadmapGeometry({
    this.curveStyle = const SCurveStyle(),
    this.curveCount = 2,
    this.curveAmplitude = 0.45,
    this.orientation = RoadmapOrientation.vertical,
    this.alongStart = 0.95,
    this.alongEnd = 0.05,
  })  : assert(curveCount > 0, 'curveCount must be positive'),
        assert(
          curveAmplitude >= 0.0 && curveAmplitude <= 0.5,
          'curveAmplitude must be within 0.0-0.5 (fraction from center)',
        ),
        assert(
          alongStart >= 0.0 && alongStart <= 1.0,
          'alongStart must be within 0.0-1.0',
        ),
        assert(
          alongEnd >= 0.0 && alongEnd <= 1.0,
          'alongEnd must be within 0.0-1.0',
        );

  /// Strategy determining the road's shape. Defaults to [SCurveStyle]; see
  /// also [ZigzagCurveStyle], [SineCurveStyle], [StraightCurveStyle],
  /// [WaypointCurveStyle] (place every turn yourself) and [CustomCurveStyle]
  /// (build the raw [Path] yourself).
  final RoadCurveStyle curveStyle;

  /// How many full swings the road makes over its extent. The road always
  /// spans exactly [alongStart] to [alongEnd], so more turns means tighter
  /// turns — never a longer road.
  final int curveCount;

  /// How far the road swings from center, as a fraction of the cross-axis
  /// extent (0.0 never leaves center, 0.5 touches the edges).
  final double curveAmplitude;

  /// Axis the road winds along.
  final RoadmapOrientation orientation;

  /// Where the road starts, as a fraction of the winding axis (0.0 is the
  /// top for vertical / left for horizontal). With [alongEnd] this places
  /// the road anywhere along its box, at any length.
  final double alongStart;

  /// Where the road ends, as a fraction of the winding axis. See [alongStart].
  final double alongEnd;

  /// How many segments this road is considered to have — used by
  /// [RoadmapSizing.fixedSegmentExtent] to compute its length. Derived from
  /// [curveStyle] so that a shape which ignores [curveCount] (such as
  /// [WaypointCurveStyle]) is still sized by its own real segment count.
  int get segmentCount => curveStyle.segmentCount(this);

  /// Maps a raw along/cross fraction of [size] to pixels, honoring
  /// [orientation]. `along` is a fraction of the whole widget; for positions
  /// relative to the road's own extent use [mapProgress].
  Offset mapPoint(double along, double cross, Size size) =>
      orientation == RoadmapOrientation.vertical
          ? Offset(cross * size.width, along * size.height)
          : Offset(along * size.width, cross * size.height);

  /// Maps a point in the road's own progress space — `t` 0.0 at the road's
  /// start to 1.0 at its end — to pixels, honoring [alongStart]/[alongEnd]
  /// and [orientation].
  ///
  /// Curve styles should use this rather than [mapPoint] so they
  /// automatically respect the road's configured extent.
  Offset mapProgress(double t, double cross, Size size) =>
      mapPoint(alongStart + (alongEnd - alongStart) * t, cross, size);

  /// Builds this road's [Path] at [size].
  Path buildPath(Size size) => curveStyle.build(size, this);

  /// Returns a copy with the given fields replaced.
  RoadmapGeometry copyWith({
    RoadCurveStyle? curveStyle,
    int? curveCount,
    double? curveAmplitude,
    RoadmapOrientation? orientation,
    double? alongStart,
    double? alongEnd,
  }) {
    return RoadmapGeometry(
      curveStyle: curveStyle ?? this.curveStyle,
      curveCount: curveCount ?? this.curveCount,
      curveAmplitude: curveAmplitude ?? this.curveAmplitude,
      orientation: orientation ?? this.orientation,
      alongStart: alongStart ?? this.alongStart,
      alongEnd: alongEnd ?? this.alongEnd,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoadmapGeometry &&
          other.curveStyle == curveStyle &&
          other.curveCount == curveCount &&
          other.curveAmplitude == curveAmplitude &&
          other.orientation == orientation &&
          other.alongStart == alongStart &&
          other.alongEnd == alongEnd);

  @override
  int get hashCode => Object.hash(
        curveStyle,
        curveCount,
        curveAmplitude,
        orientation,
        alongStart,
        alongEnd,
      );
}
