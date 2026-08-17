import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'curved_roadmap_painter.dart';
import 'curved_roadmap_style.dart';
import 'road_path.dart';
import 'roadmap_geometry.dart';
import 'roadmap_marker.dart';
import 'roadmap_sizing.dart';

/// A configurable curved, winding road — a "roadmap"/journey-path widget.
///
/// ```dart
/// CurvedRoadmap(
///   geometry: const RoadmapGeometry(curveCount: 4),
///   style: const CurvedRoadmapStyle(roadColor: Colors.brown),
///   progress: 0.4,
///   markers: [
///     RoadmapMarker(
///       distanceFraction: 0.25,
///       semanticLabel: 'Level 1',
///       child: CircleAvatar(child: Icon(Icons.star)),
///     ),
///   ],
/// )
/// ```
///
/// Configuration is split by concern: [style] is paint (and is themable via
/// `ThemeExtension`), [geometry] is shape and placement, [sizing] is layout,
/// and [progress] is state.
class CurvedRoadmap extends StatefulWidget {
  /// Creates a curved roadmap.
  const CurvedRoadmap({
    super.key,
    this.style,
    this.geometry = const RoadmapGeometry(),
    this.sizing = const RoadmapSizing.fitViewport(),
    this.backgroundColor,
    this.markers = const [],
    this.progress,
    this.keepMarkersInBounds = true,
    this.animate = false,
    this.animationDuration = const Duration(milliseconds: 900),
    this.animationCurve = Curves.easeInOut,
  }) : assert(
          progress == null || (progress >= 0.0 && progress <= 1.0),
          'progress must be within 0.0-1.0',
        );

  /// Paint configuration. If null, falls back to
  /// `Theme.of(context).extension<CurvedRoadmapStyle>()`, then to defaults.
  final CurvedRoadmapStyle? style;

  /// The road's shape and where it sits along its box.
  final RoadmapGeometry geometry;

  /// How the widget sizes itself within its parent.
  final RoadmapSizing sizing;

  /// Fills the area behind the road. Defaults to transparent.
  final Color? backgroundColor;

  /// Widgets positioned along the road.
  final List<RoadmapMarker> markers;

  /// Fraction of the road (0.0-1.0) painted as completed, in
  /// [CurvedRoadmapStyle.completedColor]. Null disables progress fill.
  final double? progress;

  /// When true (the default), marker content that would overhang the
  /// widget's bounds is shifted back inside. Individual markers can override
  /// this with [RoadmapMarker.keepInBounds].
  final bool keepMarkersInBounds;

  /// When true, the road animates drawing itself in.
  final bool animate;

  /// Duration of the draw-in animation, when [animate] is true.
  final Duration animationDuration;

  /// Curve of the draw-in animation, when [animate] is true.
  final Curve animationCurve;

  @override
  State<CurvedRoadmap> createState() => _CurvedRoadmapState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<CurvedRoadmapStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(DiagnosticsProperty<RoadmapGeometry>('geometry', geometry))
      ..add(DiagnosticsProperty<RoadmapSizing>('sizing', sizing))
      ..add(DoubleProperty('progress', progress, defaultValue: null))
      ..add(IntProperty('markers', markers.length, defaultValue: 0))
      ..add(
        FlagProperty('animate', value: animate, ifTrue: 'animating draw-in'),
      );
  }
}

class _CurvedRoadmapState extends State<CurvedRoadmap>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _reveal;

  // Cached across rebuilds (including every animation tick) so building the
  // path and computing its metrics happens once per (size, geometry).
  RoadPath? _roadPath;

  @override
  void initState() {
    super.initState();
    if (widget.animate) _startAnimation();
  }

  void _startAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _reveal = CurvedAnimation(
      parent: _controller!,
      curve: widget.animationCurve,
    );
    _controller!.forward();
  }

  @override
  void didUpdateWidget(covariant CurvedRoadmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.geometry != oldWidget.geometry) _roadPath = null;

    if (widget.animate && _controller == null) {
      _startAnimation();
    } else if (!widget.animate && _controller != null) {
      _controller!.dispose();
      _controller = null;
      _reveal = null;
    } else if (widget.animate &&
        widget.animationDuration != oldWidget.animationDuration) {
      _controller!.duration = widget.animationDuration;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  RoadPath _roadPathFor(Size size) {
    final RoadPath? cached = _roadPath;
    if (cached != null && cached.matches(size, widget.geometry)) return cached;
    final RoadPath built = RoadPath.build(size, widget.geometry);
    _roadPath = built;
    return built;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CurvedRoadmapStyle style = widget.style ??
        theme.extension<CurvedRoadmapStyle>() ??
        const CurvedRoadmapStyle();
    final Color completedColor =
        style.completedColor ?? theme.colorScheme.primary;

    Widget road = LayoutBuilder(
      builder: (context, constraints) {
        final Size size = widget.sizing.resolve(constraints, widget.geometry);
        if (size.isEmpty) return SizedBox.fromSize(size: size);
        final RoadPath roadPath = _roadPathFor(size);

        return SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: _reveal == null
                    ? CustomPaint(
                        painter: CurvedRoadmapPainter(
                          roadPath: roadPath,
                          style: style,
                          completedColor: completedColor,
                          progress: widget.progress,
                        ),
                      )
                    : AnimatedBuilder(
                        animation: _reveal!,
                        builder: (context, _) => CustomPaint(
                          painter: CurvedRoadmapPainter(
                            roadPath: roadPath,
                            style: style,
                            completedColor: completedColor,
                            progress: widget.progress,
                            revealFraction: _reveal!.value,
                          ),
                        ),
                      ),
              ),
              ..._buildMarkers(roadPath),
            ],
          ),
        );
      },
    );

    if (widget.backgroundColor != null) {
      road = ColoredBox(color: widget.backgroundColor!, child: road);
    }
    return road;
  }

  List<Widget> _buildMarkers(RoadPath roadPath) {
    if (widget.markers.isEmpty || roadPath.length <= 0) return const [];

    final List<Widget> widgets = [];
    for (final marker in widget.markers) {
      final double fraction =
          marker.distanceFraction.clamp(0.0, 1.0).toDouble();
      final double distance = fraction * roadPath.length;
      final Offset? point = roadPath.pointAt(distance);
      if (point == null) continue;

      Widget content = marker.child;
      if (marker.onTap != null) {
        content = GestureDetector(onTap: marker.onTap, child: content);
      }
      if (marker.semanticLabel != null || marker.onTap != null) {
        content = Semantics(
          label: marker.semanticLabel,
          button: marker.onTap != null,
          excludeSemantics: marker.excludeChildSemantics,
          child: content,
        );
      }

      // Only the reveal state animates; the marker's position comes from the
      // cached path and is not recomputed per frame.
      if (_reveal != null) {
        final Animation<double> reveal = _reveal!;
        content = AnimatedBuilder(
          animation: reveal,
          child: content,
          builder: (context, child) => Visibility(
            visible: distance <= roadPath.length * reveal.value + 0.5,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: true,
            child: child!,
          ),
        );
      }

      widgets.add(
        Positioned.fill(
          child: CustomSingleChildLayout(
            delegate: _MarkerLayoutDelegate(
              anchor: point + marker.offset,
              keepInside: marker.keepInBounds ?? widget.keepMarkersInBounds,
            ),
            child: content,
          ),
        ),
      );
    }
    return widgets;
  }
}

/// Centers a marker on its point of the road, then — when [keepInside] —
/// shifts it back within the widget's bounds if its measured size would
/// overhang an edge. Because the child is really measured, arbitrarily wide
/// content flips inward instead of overflowing.
class _MarkerLayoutDelegate extends SingleChildLayoutDelegate {
  const _MarkerLayoutDelegate({required this.anchor, required this.keepInside});

  final Offset anchor;
  final bool keepInside;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(constraints.biggest);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double dx = anchor.dx - childSize.width / 2;
    double dy = anchor.dy - childSize.height / 2;
    if (keepInside) {
      dx = dx.clamp(0.0, math.max(0.0, size.width - childSize.width));
      dy = dy.clamp(0.0, math.max(0.0, size.height - childSize.height));
    }
    return Offset(dx, dy);
  }

  @override
  bool shouldRelayout(_MarkerLayoutDelegate oldDelegate) =>
      oldDelegate.anchor != anchor || oldDelegate.keepInside != keepInside;
}
