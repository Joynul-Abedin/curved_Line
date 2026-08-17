import 'package:flutter/material.dart';

/// How the road's centerline is drawn.
enum RoadLineStyle {
  /// A continuous solid line.
  solid,

  /// A dashed line (the default).
  dashed,

  /// No centerline at all — just the road stroke.
  none,
}

/// Sentinel so [CurvedRoadmapStyle.copyWith] can explicitly clear nullable
/// fields (passing `null` means "leave unchanged").
const Object _unset = Object();

/// How a [CurvedRoadmap] is *painted* — colors, stroke width, centerline.
///
/// Deliberately paint-only: the road's shape lives in [RoadmapGeometry], its
/// layout in [RoadmapSizing], and its completion in `CurvedRoadmap.progress`.
/// That split is what makes this safe to install as a [ThemeExtension] — a
/// theme should set how roads look, not where they are or how far along the
/// user is.
///
/// ```dart
/// Theme(
///   data: Theme.of(context).copyWith(
///     extensions: [const CurvedRoadmapStyle(roadColor: Colors.brown)],
///   ),
///   child: const CurvedRoadmap(),
/// )
/// ```
@immutable
class CurvedRoadmapStyle extends ThemeExtension<CurvedRoadmapStyle> {
  /// Creates paint configuration for a [CurvedRoadmap].
  const CurvedRoadmapStyle({
    this.roadColor = Colors.black,
    this.roadWidth = 20.0,
    this.roadGradient,
    this.lineColor = Colors.white,
    this.lineStyle = RoadLineStyle.dashed,
    this.dashWidth = 20.0,
    this.dashSpace = 10.0,
    this.completedColor,
    this.borderColor,
    this.borderWidth = 4.0,
  })  : assert(roadWidth > 0, 'roadWidth must be positive'),
        assert(dashWidth > 0, 'dashWidth must be positive'),
        assert(dashSpace >= 0, 'dashSpace cannot be negative');

  /// Color of the road stroke. Ignored where [roadGradient] applies.
  final Color roadColor;

  /// Width of the road stroke, in logical pixels.
  final double roadWidth;

  /// Optional gradient for the road stroke; overrides [roadColor] when set.
  /// With `CurvedRoadmap.progress`, the gradient paints the *remaining*
  /// portion and [completedColor] paints the completed portion.
  final Gradient? roadGradient;

  /// Color of the centerline, when [lineStyle] is not [RoadLineStyle.none].
  final Color lineColor;

  /// How the centerline is drawn.
  final RoadLineStyle lineStyle;

  /// Dash length in logical pixels; used when [lineStyle] is [RoadLineStyle.dashed].
  final double dashWidth;

  /// Gap between dashes in logical pixels; used when [lineStyle] is [RoadLineStyle.dashed].
  final double dashSpace;

  /// Color of the completed portion when `CurvedRoadmap.progress` is set.
  /// Falls back to the ambient [ColorScheme.primary].
  final Color? completedColor;

  /// Draws a casing (kerb/shoulder) underneath the road in this color, the
  /// way printed roadmap infographics outline the tarmac. Null (the
  /// default) draws no casing.
  final Color? borderColor;

  /// How far the casing extends beyond each side of the road, in logical
  /// pixels. Only used when [borderColor] is set.
  final double borderWidth;

  @override
  CurvedRoadmapStyle copyWith({
    Color? roadColor,
    double? roadWidth,
    Object? roadGradient = _unset,
    Color? lineColor,
    RoadLineStyle? lineStyle,
    double? dashWidth,
    double? dashSpace,
    Object? completedColor = _unset,
    Object? borderColor = _unset,
    double? borderWidth,
  }) {
    return CurvedRoadmapStyle(
      roadColor: roadColor ?? this.roadColor,
      roadWidth: roadWidth ?? this.roadWidth,
      roadGradient: identical(roadGradient, _unset)
          ? this.roadGradient
          : roadGradient as Gradient?,
      lineColor: lineColor ?? this.lineColor,
      lineStyle: lineStyle ?? this.lineStyle,
      dashWidth: dashWidth ?? this.dashWidth,
      dashSpace: dashSpace ?? this.dashSpace,
      completedColor: identical(completedColor, _unset)
          ? this.completedColor
          : completedColor as Color?,
      borderColor: identical(borderColor, _unset)
          ? this.borderColor
          : borderColor as Color?,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }

  @override
  CurvedRoadmapStyle lerp(ThemeExtension<CurvedRoadmapStyle>? other, double t) {
    if (other is! CurvedRoadmapStyle) return this;
    return CurvedRoadmapStyle(
      roadColor: Color.lerp(roadColor, other.roadColor, t) ?? roadColor,
      roadWidth: roadWidth + (other.roadWidth - roadWidth) * t,
      roadGradient:
          Gradient.lerp(roadGradient, other.roadGradient, t) ?? roadGradient,
      lineColor: Color.lerp(lineColor, other.lineColor, t) ?? lineColor,
      lineStyle: t < 0.5 ? lineStyle : other.lineStyle,
      dashWidth: dashWidth + (other.dashWidth - dashWidth) * t,
      dashSpace: dashSpace + (other.dashSpace - dashSpace) * t,
      completedColor: Color.lerp(completedColor, other.completedColor, t),
      borderColor: Color.lerp(borderColor, other.borderColor, t),
      borderWidth: borderWidth + (other.borderWidth - borderWidth) * t,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CurvedRoadmapStyle &&
          other.roadColor == roadColor &&
          other.roadWidth == roadWidth &&
          other.roadGradient == roadGradient &&
          other.lineColor == lineColor &&
          other.lineStyle == lineStyle &&
          other.dashWidth == dashWidth &&
          other.dashSpace == dashSpace &&
          other.completedColor == completedColor &&
          other.borderColor == borderColor &&
          other.borderWidth == borderWidth);

  @override
  int get hashCode => Object.hash(
        roadColor,
        roadWidth,
        roadGradient,
        lineColor,
        lineStyle,
        dashWidth,
        dashSpace,
        completedColor,
      );
}
