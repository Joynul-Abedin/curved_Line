import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Which side of the road a marker's content sits on.
///
/// Sides are relative to the road's own direction of travel, not the screen,
/// so "left" stays on the same side of the tarmac whether that stretch runs
/// up, down, or across the widget.
enum RoadSide {
  /// Straddling the road, centred on the path (the default).
  on,

  /// Clear of the road, on its left as the road travels.
  left,

  /// Clear of the road, on its right as the road travels.
  right,

  /// Alternating left/right by the marker's position in the list — the
  /// zig-zag captioning used by most printed roadmap infographics. Markers
  /// at even indices go left, odd go right.
  alternating,
}

/// A widget placed at a fixed point along a [CurvedRoadmap]'s path — a level
/// icon, avatar, image, or label in a skill-tree style layout.
///
/// [child] can be any widget. For the common "icon plus title and notes"
/// case, see [RoadmapMarker.card].
@immutable
class RoadmapMarker {
  /// Creates a marker at [distanceFraction] along the road.
  const RoadmapMarker({
    required this.distanceFraction,
    required this.child,
    this.onTap,
    this.offset = Offset.zero,
    this.keepInBounds,
    this.semanticLabel,
    this.excludeChildSemantics = false,
    this.anchor,
    this.side = RoadSide.on,
    this.sideOffset = 12.0,
  }) : assert(
          distanceFraction >= 0.0 && distanceFraction <= 1.0,
          'distanceFraction must be within 0.0-1.0',
        );

  /// A ready-made card showing any combination of an image/icon, a title, and
  /// notes — the common "label this point on the road" case.
  ///
  /// Its [semanticLabel] defaults to the title and notes, so screen readers
  /// announce it without extra work.
  factory RoadmapMarker.card({
    required double distanceFraction,
    String? title,
    String? notes,
    Widget? image,
    IconData? icon,
    Color? color,
    VoidCallback? onTap,
    Offset offset = Offset.zero,
    bool? keepInBounds,
    String? semanticLabel,
    double maxWidth = 220,
    RoadSide side = RoadSide.on,
    double sideOffset = 12.0,
  }) {
    return RoadmapMarker(
      distanceFraction: distanceFraction,
      onTap: onTap,
      offset: offset,
      keepInBounds: keepInBounds,
      side: side,
      sideOffset: sideOffset,
      semanticLabel: semanticLabel ??
          [title, notes].whereType<String>().join(', ').ifEmpty(null),
      child: _RoadmapMarkerCard(
        title: title,
        notes: notes,
        image: image,
        icon: icon,
        color: color,
        maxWidth: maxWidth,
      ),
    );
  }

  /// A ringed circle sitting on the road with a caption hanging beneath it —
  /// the numbered-milestone look of printed roadmap infographics.
  ///
  /// The circle is what gets centred on the road; the caption overflows
  /// below it without shifting the circle off the path.
  factory RoadmapMarker.milestone({
    required double distanceFraction,
    required String label,
    String? title,
    String? body,
    Color? color,
    double diameter = 64,
    double captionWidth = 180,
    VoidCallback? onTap,
    String? semanticLabel,
    Offset offset = Offset.zero,
    RoadSide side = RoadSide.on,
    double sideOffset = 12.0,
  }) {
    return RoadmapMarker(
      distanceFraction: distanceFraction,
      onTap: onTap,
      offset: offset,
      side: side,
      sideOffset: sideOffset,
      // The caption deliberately overflows the circle's box.
      keepInBounds: false,
      semanticLabel: semanticLabel ??
          [label, title, body].whereType<String>().join(', ').ifEmpty(null),
      child: _MilestoneMarker(
        label: label,
        title: title,
        body: body,
        color: color,
        diameter: diameter,
        captionWidth: captionWidth,
      ),
    );
  }

  /// A teardrop map pin whose tip rests on the road, with an optional
  /// caption beside it — the pinned-step look of slide-deck roadmaps.
  factory RoadmapMarker.pin({
    required double distanceFraction,
    required String label,
    Color? color,
    double size = 44,
    VoidCallback? onTap,
    String? semanticLabel,
    Offset offset = Offset.zero,
  }) {
    return RoadmapMarker(
      distanceFraction: distanceFraction,
      onTap: onTap,
      offset: offset,
      // A pin points at its target, so it stands on its tip.
      anchor: Alignment.bottomCenter,
      semanticLabel: semanticLabel ?? label,
      child: _PinMarker(label: label, color: color, size: size),
    );
  }

  /// Position along the road, from 0.0 (start) to 1.0 (end).
  final double distanceFraction;

  /// Widget rendered at this point, centered on the road.
  final Widget child;

  /// Called when the marker is tapped. If null, the marker isn't tappable.
  final VoidCallback? onTap;

  /// Nudges the marker away from its point on the road, in pixels — e.g.
  /// `Offset(0, -40)` to float a label above the road instead of on it.
  final Offset offset;

  /// Overrides `CurvedRoadmap.keepMarkersInBounds` for this marker. When
  /// true, content that would overhang the widget's edge is shifted back
  /// inside; when false it may overhang.
  final bool? keepInBounds;

  /// Accessibility label announced for this marker. Strongly recommended
  /// when [onTap] is set — a tappable target with no label is invisible to
  /// screen reader users. Markers are exposed as buttons when tappable.
  final String? semanticLabel;

  /// Replaces the child's own semantics with [semanticLabel] rather than
  /// merging them. Useful when the child renders decorative text that would
  /// otherwise be announced twice.
  final bool excludeChildSemantics;

  /// Which point of the marker sits on its anchor point. When null (the
  /// default) it is [Alignment.center] for [RoadSide.on] markers, and for
  /// side-placed markers it is derived from the road's direction so the
  /// content's inner edge faces the tarmac.
  ///
  /// [Alignment.bottomCenter] makes a marker stand on its bottom edge,
  /// which is what a map pin wants so its tip lands on the path.
  final Alignment? anchor;

  /// Which side of the road this marker's content sits on. Defaults to
  /// [RoadSide.on] — straddling the path.
  final RoadSide side;

  /// Gap between the edge of the road and the marker, in logical pixels,
  /// when [side] is not [RoadSide.on]. Measured from the road's edge, so it
  /// stays a true clearance as the road's width changes.
  final double sideOffset;
}

extension on String {
  String? ifEmpty(String? fallback) => isEmpty ? fallback : this;
}

class _RoadmapMarkerCard extends StatelessWidget {
  const _RoadmapMarkerCard({
    this.title,
    this.notes,
    this.image,
    this.icon,
    this.color,
    required this.maxWidth,
  });

  final String? title;
  final String? notes;
  final Widget? image;
  final IconData? icon;
  final Color? color;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color effectiveColor = color ?? theme.colorScheme.primary;
    final Widget? leading = image ??
        (icon == null ? null : Icon(icon, color: theme.colorScheme.onPrimary));
    final bool hasText = title != null || notes != null;

    return Material(
      elevation: 3,
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        // Bound the card so long text wraps instead of stretching the marker
        // wider than the road it sits on.
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null)
                CircleAvatar(backgroundColor: effectiveColor, child: leading),
              if (leading != null && hasText) const SizedBox(width: 8),
              if (hasText)
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(title!, style: theme.textTheme.titleSmall),
                      if (notes != null)
                        Text(notes!, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ringed circle on the road with a caption overflowing beneath it. The
/// widget measures as just the circle, so the road point stays on the
/// circle's centre however tall the caption grows.
class _MilestoneMarker extends StatelessWidget {
  const _MilestoneMarker({
    required this.label,
    required this.title,
    required this.body,
    required this.color,
    required this.diameter,
    required this.captionWidth,
  });

  final String label;
  final String? title;
  final String? body;
  final Color? color;
  final double diameter;
  final double captionWidth;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color ring = color ?? theme.colorScheme.primary;
    final bool hasCaption = title != null || body != null;

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surface,
              border: Border.all(color: ring, width: diameter * 0.09),
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: diameter * 0.3,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (hasCaption)
            Positioned(
              top: diameter + 8,
              width: captionWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(color: ring),
                    ),
                  if (body != null)
                    Text(
                      body!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A teardrop map pin: a filled disc tapering to a point at the bottom.
class _PinMarker extends StatelessWidget {
  const _PinMarker({
    required this.label,
    required this.color,
    required this.size,
  });

  final String label;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color fill = color ?? theme.colorScheme.primary;
    return SizedBox(
      width: size,
      height: size * 1.35,
      child: CustomPaint(
        painter: _PinPainter(fill),
        child: Padding(
          padding: EdgeInsets.only(bottom: size * 0.35),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: _onColor(fill),
                fontSize: size * 0.32,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _onColor(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF000000);
}

class _PinPainter extends CustomPainter {
  const _PinPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset centre = Offset(radius, radius);
    final Offset tip = Offset(radius, size.height);

    // Circle, plus a triangle that meets it along its tangents so the join
    // reads as one teardrop rather than a disc with a spike.
    final double sinA = radius / (tip - centre).distance;
    final double angle = math.asin(sinA.clamp(-1.0, 1.0));

    final path = Path()
      ..addArc(
        Rect.fromCircle(center: centre, radius: radius),
        math.pi / 2 - angle,
        2 * angle - 2 * math.pi,
      )
      ..lineTo(tip.dx, tip.dy)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PinPainter oldDelegate) => oldDelegate.color != color;
}
