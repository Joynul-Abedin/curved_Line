import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'roadmap_geometry.dart';

double _clamp(double v, double lo, double hi) =>
    v < lo ? lo : (v > hi ? hi : v);

/// A road's [Path] together with its precomputed metrics.
///
/// Building the path and calling `computeMetrics()` is the expensive part of
/// drawing a road (and notably slow on web), so it happens once per
/// (size, geometry) here and is shared by the painter and by marker
/// positioning — rather than being recomputed by each, every frame.
///
/// Dashed centerlines are memoized too: redrawing with unchanged dash
/// parameters reuses the previous path instead of re-extracting every dash.
/// Note the memo only holds the most recent result, so a draw-in animation
/// (whose revealed length changes every frame) still rebuilds its dashes per
/// frame; steady-state repaints — color changes, progress changes, scrolling
/// — reuse the cached path.
class RoadPath {
  RoadPath._(this.size, this.geometry, this.path, this._metrics, this.length);

  /// Builds the road for [geometry] at [size].
  factory RoadPath.build(Size size, RoadmapGeometry geometry) {
    final Path path = geometry.buildPath(size);
    final List<ui.PathMetric> metrics = path.computeMetrics().toList();
    final double length = metrics.fold(0.0, (sum, m) => sum + m.length);
    return RoadPath._(size, geometry, path, metrics, length);
  }

  /// Canvas size this path was built for.
  final Size size;

  /// Geometry this path was built from.
  final RoadmapGeometry geometry;

  /// The road's path, in pixels.
  final Path path;

  final List<ui.PathMetric> _metrics;

  /// Total arc length of the road, in pixels.
  final double length;

  Path? _dashCache;
  double? _dashCacheWidth;
  double? _dashCacheSpace;
  double? _dashCacheUpTo;

  /// True when this path is still valid for [size] and [geometry] — used to
  /// decide whether a cached instance can be reused.
  bool matches(Size size, RoadmapGeometry geometry) =>
      this.size == size && this.geometry == geometry;

  /// The point at [distance] along the road, or null if the road is empty.
  Offset? pointAt(double distance) {
    double base = 0.0;
    for (final metric in _metrics) {
      if (distance <= base + metric.length) {
        return metric.getTangentForOffset(distance - base)?.position;
      }
      base += metric.length;
    }
    if (_metrics.isEmpty) return null;
    final ui.PathMetric last = _metrics.last;
    return last.getTangentForOffset(last.length)?.position;
  }

  /// A sub-path covering arc length [from]..[to] along the whole road.
  Path extract(double from, double to) {
    final Path result = Path();
    if (to <= from) return result;
    // The whole road is the common case (no progress fill, no draw-in
    // animation); returning it directly avoids copying every segment on
    // each repaint.
    if (from <= 0 && to >= length) return path;
    double base = 0.0;
    for (final metric in _metrics) {
      final double localFrom = _clamp(from - base, 0.0, metric.length);
      final double localTo = _clamp(to - base, 0.0, metric.length);
      if (localTo > localFrom) {
        result.addPath(metric.extractPath(localFrom, localTo), Offset.zero);
      }
      base += metric.length;
    }
    return result;
  }

  /// A dashed centerline covering the first [upTo] pixels of the road.
  ///
  /// Memoized on the dash parameters, so repaints that don't change them
  /// (color changes, progress changes, scrolling) reuse the built path
  /// instead of re-extracting every dash.
  Path dashed({
    required double dashWidth,
    required double dashSpace,
    required double upTo,
  }) {
    if (_dashCache != null &&
        _dashCacheWidth == dashWidth &&
        _dashCacheSpace == dashSpace &&
        _dashCacheUpTo == upTo) {
      return _dashCache!;
    }
    final Path result = Path();
    final double stride = dashWidth + dashSpace;
    if (stride > 0) {
      double distance = 0.0;
      while (distance < upTo) {
        result.addPath(
          extract(distance, _clamp(distance + dashWidth, 0.0, upTo)),
          Offset.zero,
        );
        distance += stride;
      }
    }
    _dashCache = result;
    _dashCacheWidth = dashWidth;
    _dashCacheSpace = dashSpace;
    _dashCacheUpTo = upTo;
    return result;
  }

  @override
  String toString() =>
      '${objectRuntimeType(this, 'RoadPath')}(size: $size, length: '
      '${length.toStringAsFixed(1)})';
}
