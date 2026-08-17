import 'package:flutter/widgets.dart';

/// How the road turns at a [RoadWaypoint].
enum RoadTurnType {
  /// The road curves smoothly near this point (does not pass exactly
  /// through it — the standard trade-off for a smooth multi-point curve).
  smooth,

  /// The road passes exactly through this point with a sharp corner.
  sharp,
}

/// One user-placed turn in a `WaypointCurveStyle` road.
///
/// This is the "full control" way to shape a road: instead of a uniform
/// preset, you place exactly the turns you want, how far each swings, and
/// whether each is a smooth curve or a sharp corner.
@immutable
class RoadWaypoint {
  /// Creates a turn at [cross], optionally pinned to [at].
  const RoadWaypoint({
    required this.cross,
    this.at,
    this.turn = RoadTurnType.smooth,
  })  : assert(cross >= 0.0 && cross <= 1.0, 'cross must be within 0.0-1.0'),
        assert(
          at == null || (at >= 0.0 && at <= 1.0),
          'at must be within 0.0-1.0',
        );

  /// How far this turn swings across the road's width, from 0.0 (one edge)
  /// to 1.0 (the other edge); 0.5 is center. This is "how much curve".
  final double cross;

  /// Where this turn sits along the road, from 0.0 (the road's start) to
  /// 1.0 (its end) — relative to the road's own extent, so it respects
  /// `CurvedRoadmapStyle.alongStart`/`alongEnd`. If null, waypoints are
  /// spaced evenly.
  final double? at;

  /// Whether the road curves smoothly through this point or turns sharply.
  final RoadTurnType turn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoadWaypoint &&
          other.cross == cross &&
          other.at == at &&
          other.turn == turn);

  @override
  int get hashCode => Object.hash(cross, at, turn);
}
