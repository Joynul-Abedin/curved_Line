# curved_roadmap

[![pub package](https://img.shields.io/pub/v/curved_roadmap.svg)](https://pub.dev/packages/curved_roadmap)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![platforms](https://img.shields.io/badge/platforms-all%206-brightgreen.svg)](https://pub.dev/packages/curved_roadmap)

Curved, winding roadmap and journey paths for Flutter — the road-shaped
progress graphic used in onboarding flows, learning paths, project timelines
and slide-deck infographics.

Pure Dart and Flutter: no platform channels, no native dependencies, and it
runs on all six platforms.

| Markers + progress | Marker cards | Gradient + animation |
|---|---|---|
| <img src="https://raw.githubusercontent.com/Joynul-Abedin/curved_Line/main/doc/screenshots/markers_progress.png" width="200"> | <img src="https://raw.githubusercontent.com/Joynul-Abedin/curved_Line/main/doc/screenshots/marker_cards.png" width="200"> | <img src="https://raw.githubusercontent.com/Joynul-Abedin/curved_Line/main/doc/screenshots/gradient_animation.png" width="200"> |

| Serpentine milestones | Serpentine with map pins | Captions beside the road |
|---|---|---|
| <img src="https://raw.githubusercontent.com/Joynul-Abedin/curved_Line/main/doc/screenshots/serpentine_milestones.png" width="200"> | <img src="https://raw.githubusercontent.com/Joynul-Abedin/curved_Line/main/doc/screenshots/serpentine_pins.png" width="200"> | <img src="https://raw.githubusercontent.com/Joynul-Abedin/curved_Line/main/doc/screenshots/side_captions.png" width="200"> |

Every screen above is in the [example app](example), along with horizontal
scrollable roads, curve variants, theming and arbitrary placement.

## Install

```yaml
dependencies:
  curved_roadmap: ^0.1.1
```

## Quick start

```dart
import 'package:curved_roadmap/curved_roadmap.dart';

CurvedRoadmap(
  geometry: const RoadmapGeometry(curveCount: 3),
  style: const CurvedRoadmapStyle(roadColor: Colors.black87),
  progress: 0.4,
  markers: [
    for (int i = 1; i <= 5; i++)
      RoadmapMarker(
        distanceFraction: i / 6,
        semanticLabel: 'Level $i',
        onTap: () => print('Level $i'),
        child: CircleAvatar(child: Text('$i')),
      ),
  ],
)
```

The road fills its parent's constraints, so give it a bounded box — a
`Scaffold` body, an `Expanded`, or a `SizedBox`.

## What you can control

| Want to… | Use |
|---|---|
| Change the road's shape | [`curveStyle`](#curve-style-variants) — S-curve, serpentine, zigzag, sine, straight |
| Draw a printed-style infographic | [`SerpentineCurveStyle`](#infographic-roadmaps) |
| Place captions beside the road | [`RoadmapMarker.side`](#nodes-on-over-or-under-the-road) |
| Position the road in its box | [`alongStart`/`alongEnd`](#placing-the-road-anywhere-any-length) |
| Shape every turn by hand | [`WaypointCurveStyle`](#full-manual-control-over-the-curves) |
| Show completion | [`progress`](#progress-fill) |
| Animate it in | [`animate`](#draw-in-animation) |
| Go longer than one screen | [`RoadmapSizing.fixedSegmentExtent`](#scrollable-longer-than-one-screen-roadmaps) |

## Placing the road: anywhere, any length

The road always spans exactly the extent you ask for — `curveCount` changes
how *tight* the turns are, never how much space the road takes. Use
`alongStart`/`alongEnd` (fractions of the winding axis) to place it:

```dart
// Only the top half of the box.
CurvedRoadmap(
  geometry: const RoadmapGeometry(alongStart: 0.5, alongEnd: 0.0),
)
```

| Field | What it controls |
|---|---|
| `geometry.alongStart` / `alongEnd` | Where the road begins and ends — any position, any length. Swap them to run it backwards |
| `sizing.crossExtent` | Fixes the road's width in pixels (required under unbounded constraints) |
| `RoadmapSizing.fixedSegmentExtent` | Fixed pixels per segment, for roads longer than one screen |
| `geometry.orientation` | Which axis it winds along |

It composes normally — drop it in a `Card`, a `Row`, a `ListView` item, or
anywhere else; it sizes to its constraints like any other widget.

## Configuration is split by concern

| Object | Owns | Themable |
|---|---|---|
| `CurvedRoadmapStyle` | Paint: colors, stroke width, gradient, centerline | Yes, via `ThemeExtension` |
| `RoadmapGeometry` | Shape: curve style, turn count, amplitude, orientation, extent | No |
| `RoadmapSizing` | Layout: fit-to-parent or fixed pixels per segment | No |
| `progress` (widget) | State: how far along the road is | No |

```dart
CurvedRoadmap(
  style: const CurvedRoadmapStyle(
    roadColor: Colors.brown,
    roadWidth: 24,
    lineColor: Colors.amber,
    lineStyle: RoadLineStyle.dashed, // or .solid / .none
  ),
  geometry: const RoadmapGeometry(
    curveCount: 4,
    curveAmplitude: 0.45, // 0.0-0.5, fraction from center
    orientation: RoadmapOrientation.vertical, // or .horizontal
  ),
  progress: 0.4,
)
```

Only paint lives in the theme extension, so theming colors never drags
layout or progress state along with it.

Or set it once for a whole subtree via `ThemeData.extensions`:

```dart
Theme(
  data: Theme.of(context).copyWith(
    extensions: [const CurvedRoadmapStyle(roadColor: Colors.brown)],
  ),
  child: const CurvedRoadmap(), // picks up the style automatically
)
```

## Milestones / markers

Place widgets along the path — icons, avatars, labels — with tap callbacks:

```dart
CurvedRoadmap(
  markers: [
    RoadmapMarker(
      distanceFraction: 0.25, // 0.0 (start) - 1.0 (end)
      onTap: () => print('Level 1'),
      child: const CircleAvatar(child: Icon(Icons.star)),
    ),
  ],
)
```

## Progress fill

```dart
CurvedRoadmap(
  progress: 0.4, // 0.0-1.0
  style: const CurvedRoadmapStyle(completedColor: Colors.orange),
)
```

`completedColor` falls back to the ambient `ColorScheme.primary`.

## Draw-in animation

```dart
CurvedRoadmap(
  animate: true,
  animationDuration: const Duration(seconds: 2),
)
```

## Gradient stroke

```dart
CurvedRoadmap(
  style: const CurvedRoadmapStyle(
    roadGradient: LinearGradient(colors: [Colors.purple, Colors.orange]),
  ),
)
```

## Curve style variants

`curveStyle` swaps the road's shape entirely — `SCurveStyle` (default),
`SerpentineCurveStyle`, `ZigzagCurveStyle`, `SineCurveStyle`, or
`StraightCurveStyle`:

```dart
CurvedRoadmap(
  geometry: const RoadmapGeometry(curveStyle: SineCurveStyle()),
)
```

## Infographic roadmaps

`SerpentineCurveStyle` is the classic printed-roadmap layout: straight runs
joined by U-turns at alternating ends, one row of milestones per run.

```dart
CurvedRoadmap(
  geometry: const RoadmapGeometry(
    curveStyle: SerpentineCurveStyle(rows: 3),
    curveAmplitude: 0.44,
  ),
  style: const CurvedRoadmapStyle(
    roadColor: Color(0xFF2E2E2E),
    roadWidth: 26,
    borderColor: Color(0xFFBDBDBD), // kerb/casing under the tarmac
    borderWidth: 3,
  ),
  markers: [
    RoadmapMarker.milestone(
      distanceFraction: 0,
      label: 'START',
      diameter: 104,
    ),
    RoadmapMarker.milestone(
      distanceFraction: 0.25,
      label: '1',
      title: 'DISCOVERY',
      body: 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit.',
      color: Colors.teal,
    ),
  ],
)
```

### Nodes on, over or under the road

`side` decides where a marker's content sits relative to the road, and
`sideOffset` how far clear of the tarmac it sits:

```dart
CurvedRoadmap(
  markers: [
    // The pin sits on the path...
    RoadmapMarker.pin(distanceFraction: 0.25, label: '01'),
    // ...and its caption sits clear of it, swapping sides down the road.
    RoadmapMarker(
      distanceFraction: 0.25,
      side: RoadSide.alternating, // or .left / .right / .on
      sideOffset: 24,             // gap from the road's edge, not its centre
      child: const MyCaption(),
    ),
  ],
)
```

| `RoadSide` | Where the content goes |
|---|---|
| `on` | Straddling the path (the default) |
| `left` / `right` | Clear of the road, relative to its direction of travel |
| `alternating` | Swaps side by list position — even index left, odd right |

Sides follow the **road**, not the screen: `left` stays on the same side of
the tarmac whether that stretch runs up, down or across, because placement
is computed from the road's tangent at that point. `sideOffset` is measured
from the road's edge, so it stays a true clearance when `roadWidth` changes.

Side-placed markers are not clamped back inside the widget — pulling them in
would drag them onto the road they were asked to sit clear of. Give the
widget enough room, or set `keepInBounds: true` on the marker to override.

For finer control, `anchor` picks which point of the marker meets its
placement point; it defaults to facing the content's inner edge at the road.

`RoadmapMarker.milestone` puts a ringed circle on the road with its caption
hanging beneath; `RoadmapMarker.pin` drops a teardrop map pin whose tip rests
on the path (it anchors on its tip rather than its centre — see
`RoadmapMarker.anchor` if you need that for your own markers).

The turns are semicircles when there's room and flatten into ellipses when
there isn't, so the runs never collapse on a narrow box. This layout wants
width: give it a wide box, or scroll it horizontally, as the example does.

## Full manual control over the curves

Presets (`SCurveStyle`, `ZigzagCurveStyle`, etc.) use uniform `curveCount`/
`curveAmplitude`. For complete control over every turn — how far it swings,
where it sits, and whether it's a smooth curve or a sharp corner — use
`WaypointCurveStyle`:

```dart
CurvedRoadmap(
  geometry: const RoadmapGeometry(
    curveStyle: WaypointCurveStyle([
      RoadWaypoint(cross: 0.15),
      RoadWaypoint(cross: 0.85),
      RoadWaypoint(cross: 0.3, turn: RoadTurnType.sharp),
      RoadWaypoint(cross: 0.9),
    ]),
  ),
)
```

`cross` (0.0-1.0) is how far that turn swings across the road; `at`
(0.0-1.0 along the road) is optional and defaults to even spacing; `turn`
picks smooth vs. sharp per turn. For total control beyond that,
`CustomCurveStyle` hands you the canvas size and style and lets you build
the `Path` yourself:

```dart
CurvedRoadmap(
  geometry: RoadmapGeometry(
    curveStyle: CustomCurveStyle((size, geometry) {
      // geometry.mapProgress(t, cross, size) honors orientation/extent.
      return Path()
        ..moveTo(0, size.height)
        ..lineTo(size.width, 0);
    }),
  ),
)
```

Hoist a `CustomCurveStyle`'s function to a field or top-level function
rather than writing it inline — curve styles are compared to decide when to
repaint, and a fresh closure each build repaints every frame.

## Rich marker content — images, titles, notes

`RoadmapMarker.child` accepts any widget, so anything (an `Image`, a
`Column` of your own design, a custom-painted badge) can sit on the road.
For the common case — an icon/image plus a title and notes — `RoadmapMarker.card`
builds it for you:

```dart
CurvedRoadmap(
  markers: [
    RoadmapMarker.card(
      distanceFraction: 0.3,
      title: 'Rest stop',
      notes: 'Great photo spot',
      icon: Icons.landscape, // or `image: Image.asset(...)`
      color: Colors.teal,
      onTap: () => print('tapped'),
    ),
  ],
)
```

Pass `semanticLabel` on markers you build yourself — tappable markers are
exposed to screen readers as buttons, and a button with no label is
invisible to them. `RoadmapMarker.card` labels itself from its title and
notes.

Markers are measured and kept inside the widget's bounds, so wide content
near an edge shifts inward instead of overflowing. Turn that off per marker
with `keepInBounds: false` (or globally via
`CurvedRoadmap.keepMarkersInBounds`), and nudge a marker off the road with
`offset: const Offset(0, -40)`.

## Scrollable, longer-than-one-screen roadmaps

Use `RoadmapSizing.fixedSegmentExtent` and wrap in a `SingleChildScrollView`
along the winding axis. Length follows the shape's own segment count, so a
`WaypointCurveStyle` grows with the turns you placed:

```dart
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: CurvedRoadmap(
    geometry: const RoadmapGeometry(
      orientation: RoadmapOrientation.horizontal,
      curveCount: 8,
    ),
    sizing: const RoadmapSizing.fixedSegmentExtent(260),
  ),
)
```

## Accessibility

Tappable markers are exposed as buttons and merge their child's labels, so a
`Text` or a labelled `Icon` announces itself. For markers whose content
carries no text of its own, pass `semanticLabel` — an unlabelled button is
invisible to screen reader users.

## Contributing

Issues and pull requests are welcome at
[github.com/Joynul-Abedin/curved_Line](https://github.com/Joynul-Abedin/curved_Line/issues).

```bash
flutter test                       # everything, including goldens
flutter test --exclude-tags golden # skip goldens off the reference platform
flutter test --update-goldens      # after an intended visual change
```

Golden images are rendered by a specific engine version and host platform, so
they are tagged `golden` and expected to differ elsewhere.

## License

MIT — see [LICENSE](LICENSE).
