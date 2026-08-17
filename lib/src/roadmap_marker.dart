import 'package:flutter/material.dart';

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
  }) {
    return RoadmapMarker(
      distanceFraction: distanceFraction,
      onTap: onTap,
      offset: offset,
      keepInBounds: keepInBounds,
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
