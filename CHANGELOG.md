## 0.1.0

Initial release.

- `CurvedRoadmap` widget for drawing a configurable curved, winding road path.
- `CurvedRoadmapStyle` controls road color/width/gradient, centerline
  (solid/dashed/none), curve count and amplitude, orientation and direction.
- Road placement and length: `alongStart`/`alongEnd` position the road
  anywhere along its box at any length, `crossExtent` fixes its width, and
  `curveCount` changes only how tight the turns are — never how much space
  the road occupies.
- Full manual shape control: `WaypointCurveStyle` places every turn
  individually (position, swing, smooth or sharp), and `CustomCurveStyle`
  hands over raw `Path` construction.
- Preset shapes: S-curve (default), zigzag, sine, straight.
- Markers: any widget along the path, plus a `RoadmapMarker.card` factory for
  title/notes/image content. Markers support tap callbacks, pixel `offset`,
  and are kept inside the widget's bounds by default.
- Progress fill (completed vs. remaining), path draw-in animation, and
  gradient strokes (which compose with progress fill).
- Scrollable roadmaps longer than one screen via
  `RoadSizingMode.fixedSegmentExtent`.
- Theming through `ThemeExtension<CurvedRoadmapStyle>` — paint only, so a
  theme never carries layout or progress state.
- Accessibility: markers take a `semanticLabel` and are exposed as buttons
  when tappable; `RoadmapMarker.card` labels itself from its content.
- Performance: the road path and its metrics are built once per
  (size, geometry) and shared by the painter and marker positioning, and
  dashed centerlines are memoized — an animating road does not rebuild
  geometry per frame.
- Golden tests cover the default road, curve variants, progress, gradients,
  waypoints, extent, and marker bounds. They are tagged `golden`, so CI on a
  non-reference platform can run `flutter test --exclude-tags golden`.
- `SineCurveStyle` interpolates the true sine at four points per quarter-wave,
  keeping it within a pixel of an exact wave instead of visibly undershooting
  the peaks.
- Analysis enforces `public_member_api_docs`, so the whole public API is
  documented.
