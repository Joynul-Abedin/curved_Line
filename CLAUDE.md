# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get                       # install deps
flutter test                          # all tests (includes goldens)
flutter test --exclude-tags golden    # skip goldens (non-reference platform)
flutter test --update-goldens         # regenerate goldens after an intended visual change
flutter test test/widget_test.dart    # single file
flutter analyze                       # lint
dart format .                         # format
flutter pub publish --dry-run         # pre-publish validation

cd example && flutter run             # run the demo app
```

Published package name: `curved_roadmap` (repo dir is still `curved_Line`). Dart SDK `>=3.3.0 <4.0.0`.

## Architecture

Pure-Dart Flutter widget package — no platform channels, so no plugin scaffolding at the root. `example/` is a full app that consumes the package via `path: ../`.

`lib/curved_roadmap.dart` is the barrel; everything real is in `lib/src/`.

**The central idea: normalized progress space.** Curve shapes never touch pixels. They work in `t` (0.0 at the road's start → 1.0 at its end) and `cross` (0.0–1.0 across the road's width, 0.5 = center). `RoadmapGeometry.mapProgress(t, cross, size)` converts to pixels, applying orientation and the `alongStart`/`alongEnd` extent. Consequences worth knowing before editing:

- A road **always** spans exactly `alongStart`→`alongEnd`, whatever `curveCount` is. More turns means tighter turns, never a longer road. Any new curve style must preserve this — there's a test asserting it for counts 1…20.
- To reverse direction, swap `alongStart`/`alongEnd`. There is deliberately no `reverse` flag (it was removed as a redundant second spelling).

**Configuration is split by concern** — do not merge these back together:

| Class | Owns | Notes |
|---|---|---|
| `CurvedRoadmapStyle` | Paint only | Themable via `ThemeExtension`. Keep it paint-only: theming must not carry layout or state. |
| `RoadmapGeometry` | Shape + extent | Path depends only on this + size. |
| `RoadmapSizing` | Layout | Named constructors `fitViewport` / `fixedSegmentExtent`. |
| `CurvedRoadmap.progress` | State | A widget property, never style. |

**`RoadPath` ([lib/src/road_path.dart](lib/src/road_path.dart)) is the performance boundary.** It builds the `Path` and its `PathMetric`s once per (size, geometry), cached in `_CurvedRoadmapState`, and is shared by the painter *and* marker positioning. Both used to compute it independently, every frame. Keep it that way:
- `extract(0, length)` returns the path itself, not a copy — the common repaint case.
- `dashed(...)` memoizes one entry; a draw-in animation still rebuilds dashes per frame (documented limitation, no cheap fix without a stroke-outline API).
- The path depends on geometry only, so a style change must **not** invalidate it.

**Curve styles** (`RoadCurveStyle` subclasses) must implement `==`/`hashCode` — geometry equality decides whether the path is rebuilt, so a style that compares equal after its parameters changed renders stale. `segmentCount()` drives `fixedSegmentExtent` sizing; override it when the shape defines its own segments (`WaypointCurveStyle` returns `waypoints.length - 1`).

`SineCurveStyle` interpolates the true sine at four points per quarter-wave. Using on-curve points as Bézier controls looks plausible but undershoots peaks by ~9px; a test asserts deviation stays under 1px.

**Markers** are real widgets in a `Stack`, positioned via `CustomSingleChildLayout` so the child is measured and clamped inside the widget's bounds (wide labels near an edge flip inward). Tappable markers become `Semantics` buttons; child labels merge automatically.

## Conventions

- `analysis_options.yaml` enforces `public_member_api_docs` — every public member needs a doc comment or analyze fails.
- Goldens are tagged `golden`; they are platform/engine-dependent.
- Root `pubspec.lock` is gitignored (packages don't commit lockfiles); `example/`'s is committed.
- `.pubignore` keeps this file, the plan file, and `test/goldens/` out of the published archive.
