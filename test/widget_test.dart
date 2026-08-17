import 'dart:math' as math;

import 'package:curved_roadmap/curved_roadmap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CurvedRoadmapPainter _painterOf(WidgetTester tester) {
  return tester
      .widget<CustomPaint>(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is CurvedRoadmapPainter,
        ),
      )
      .painter as CurvedRoadmapPainter;
}

Widget _sized(Widget child, {double width = 300, double height = 600}) =>
    MaterialApp(
      home: Center(
        child: SizedBox(width: width, height: height, child: child),
      ),
    );

void main() {
  group('rendering', () {
    testWidgets('renders a CustomPaint with CurvedRoadmapPainter', (
      tester,
    ) async {
      await tester.pumpWidget(_sized(const CurvedRoadmap()));
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is CurvedRoadmapPainter,
        ),
        findsOneWidget,
      );
    });

    testWidgets('passes style through to the painter', (tester) async {
      const style = CurvedRoadmapStyle(roadColor: Colors.red);
      await tester.pumpWidget(_sized(const CurvedRoadmap(style: style)));
      expect(_painterOf(tester).style, style);
    });

    testWidgets('falls back to a ThemeExtension style', (tester) async {
      const themeStyle = CurvedRoadmapStyle(roadColor: Colors.brown);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [themeStyle]),
          home: const SizedBox(width: 300, height: 600, child: CurvedRoadmap()),
        ),
      );
      expect(_painterOf(tester).style, themeStyle);
    });

    testWidgets('completedColor falls back to the theme primary', (
      tester,
    ) async {
      final theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const SizedBox(
            width: 300,
            height: 600,
            child: CurvedRoadmap(progress: 0.5),
          ),
        ),
      );
      expect(_painterOf(tester).completedColor, theme.colorScheme.primary);
    });
  });

  group('road geometry', () {
    Rect boundsFor(
      RoadmapGeometry geometry, [
      Size size = const Size(300, 600),
    ]) =>
        RoadPath.build(size, geometry).path.getBounds();

    test('road stays inside the canvas for any curveCount', () {
      // Regression: a fixed per-curve schedule used to run off-canvas once
      // curveCount exceeded ~5.
      for (final count in [1, 2, 5, 8, 20]) {
        for (final curveStyle in const <RoadCurveStyle>[
          SCurveStyle(),
          ZigzagCurveStyle(),
          SineCurveStyle(),
        ]) {
          final bounds = boundsFor(
            RoadmapGeometry(curveCount: count, curveStyle: curveStyle),
          );
          expect(
            bounds.top,
            greaterThanOrEqualTo(-1),
            reason: '$curveStyle count=$count overflows the top',
          );
          expect(
            bounds.bottom,
            lessThanOrEqualTo(601),
            reason: '$curveStyle count=$count overflows the bottom',
          );
        }
      }
    });

    test('road spans the same extent regardless of curveCount', () {
      // The count is the subject of this test, so state both sides.
      // ignore: avoid_redundant_argument_values
      final two = boundsFor(const RoadmapGeometry(curveCount: 2));
      final ten = boundsFor(const RoadmapGeometry(curveCount: 10));
      expect(two.top, closeTo(ten.top, 1.0));
      expect(two.bottom, closeTo(ten.bottom, 1.0));
    });

    test('alongStart/alongEnd place the road anywhere, at any length', () {
      final topHalf = boundsFor(
        const RoadmapGeometry(alongStart: 0.5, alongEnd: 0.0),
      );
      expect(topHalf.bottom, lessThanOrEqualTo(301));

      final middle = boundsFor(
        const RoadmapGeometry(alongStart: 0.6, alongEnd: 0.4),
      );
      expect(middle.top, greaterThanOrEqualTo(600 * 0.4 - 1));
      expect(middle.bottom, lessThanOrEqualTo(600 * 0.6 + 1));
    });

    test('swapping alongStart/alongEnd reverses the winding direction', () {
      const size = Size(300, 600);
      final forward = RoadPath.build(size, const RoadmapGeometry());
      final backward = RoadPath.build(
        size,
        const RoadmapGeometry(alongStart: 0.05, alongEnd: 0.95),
      );
      expect(
        forward.pointAt(0)!.dy,
        greaterThan(forward.pointAt(forward.length)!.dy),
      );
      expect(
        backward.pointAt(0)!.dy,
        lessThan(backward.pointAt(backward.length)!.dy),
      );
    });

    test('mapProgress respects the configured extent', () {
      const geometry = RoadmapGeometry(alongStart: 0.8, alongEnd: 0.2);
      const size = Size(300, 600);
      expect(geometry.mapProgress(0, 0.5, size).dy, closeTo(480, 0.001));
      expect(geometry.mapProgress(1, 0.5, size).dy, closeTo(120, 0.001));
    });

    test('horizontal orientation maps along->x, cross->y', () {
      const size = Size(600, 300);
      const vertical = RoadmapGeometry();
      const horizontal = RoadmapGeometry(
        orientation: RoadmapOrientation.horizontal,
      );

      final v = vertical.mapPoint(0.2, 0.8, size);
      expect(v.dx, closeTo(480, 0.001));
      expect(v.dy, closeTo(60, 0.001));

      final h = horizontal.mapPoint(0.2, 0.8, size);
      expect(h.dx, closeTo(120, 0.001));
      expect(h.dy, closeTo(240, 0.001));
    });

    for (final curveStyle in const <RoadCurveStyle>[
      SCurveStyle(),
      ZigzagCurveStyle(),
      SineCurveStyle(),
      StraightCurveStyle(),
    ]) {
      test('$curveStyle builds a non-empty path', () {
        final road = RoadPath.build(
          const Size(300, 600),
          RoadmapGeometry(curveStyle: curveStyle),
        );
        expect(road.length, greaterThan(0));
      });
    }
  });

  group('SineCurveStyle accuracy', () {
    test('stays within a pixel of a true sine wave', () {
      // Regression: on-curve control points undershot the peaks by ~9px.
      const size = Size(300, 600);
      const geometry = RoadmapGeometry(
        // ignore: avoid_redundant_argument_values
        curveCount: 2,
        curveStyle: SineCurveStyle(),
      );
      final road = RoadPath.build(size, geometry);
      double maxDeviation = 0;
      for (int i = 0; i <= 400; i++) {
        final point = road.pointAt(i / 400 * road.length)!;
        final t = (geometry.alongStart - point.dy / size.height) /
            (geometry.alongStart - geometry.alongEnd);
        final expectedX = (0.5 +
                geometry.curveAmplitude *
                    math.sin(2 * math.pi * geometry.curveCount * t)) *
            size.width;
        maxDeviation = math.max(maxDeviation, (point.dx - expectedX).abs());
      }
      expect(maxDeviation, lessThan(1.0));
    });
  });

  group('WaypointCurveStyle', () {
    test('passes exactly through sharp waypoints', () {
      const geometry = RoadmapGeometry(
        curveStyle: WaypointCurveStyle([
          RoadWaypoint(cross: 0.2, turn: RoadTurnType.sharp),
          RoadWaypoint(cross: 0.8, turn: RoadTurnType.sharp),
          RoadWaypoint(cross: 0.5, turn: RoadTurnType.sharp),
        ]),
      );
      const size = Size(300, 600);
      final road = RoadPath.build(size, geometry);
      expect(road.length, greaterThan(0));

      final expected = geometry.mapProgress(0.5, 0.8, size);
      bool onPath = false;
      for (double d = 0; d <= road.length; d += 1) {
        if ((road.pointAt(d)! - expected).distance < 1.0) {
          onPath = true;
          break;
        }
      }
      expect(onPath, isTrue);
    });

    test('requires at least 2 waypoints', () {
      const curveStyle = WaypointCurveStyle([RoadWaypoint(cross: 0.5)]);
      expect(
        () => curveStyle.build(const Size(300, 600), const RoadmapGeometry()),
        throwsA(isA<AssertionError>()),
      );
    });

    test('segmentCount follows its own waypoints, not curveCount', () {
      // Regression: fixedSegmentExtent used to size a waypoint road by the
      // unrelated curveCount field.
      const geometry = RoadmapGeometry(
        // Proving this value is *not* what sizes a waypoint road.
        // ignore: avoid_redundant_argument_values
        curveCount: 2,
        curveStyle: WaypointCurveStyle([
          RoadWaypoint(cross: 0.1),
          RoadWaypoint(cross: 0.9),
          RoadWaypoint(cross: 0.2),
          RoadWaypoint(cross: 0.8),
          RoadWaypoint(cross: 0.5),
        ]),
      );
      expect(geometry.segmentCount, 4);

      const sizing = RoadmapSizing.fixedSegmentExtent(100);
      final size = sizing.resolve(
        const BoxConstraints(maxWidth: 300, maxHeight: 600),
        geometry,
      );
      expect(size.height, 400); // 4 segments, not curveCount (2) * 100.
    });
  });

  group('CustomCurveStyle', () {
    test('delegates entirely to the provided builder', () {
      final custom = CustomCurveStyle(
        (size, geometry) => Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, size.height),
      );
      final road = RoadPath.build(
        const Size(300, 600),
        RoadmapGeometry(curveStyle: custom),
      );
      expect(road.path.getBounds(), const Rect.fromLTWH(0, 0, 300, 600));
    });

    test('reports its own segment count when given one', () {
      final custom = CustomCurveStyle(
        (size, geometry) => Path()..lineTo(10, 10),
        segments: 7,
      );
      expect(RoadmapGeometry(curveStyle: custom).segmentCount, 7);
    });
  });

  group('sizing', () {
    test('fitViewport uses the incoming constraints', () {
      const sizing = RoadmapSizing.fitViewport();
      expect(
        sizing.resolve(
          const BoxConstraints(maxWidth: 320, maxHeight: 480),
          const RoadmapGeometry(),
        ),
        const Size(320, 480),
      );
    });

    test('fixedSegmentExtent sizes by segments, crossExtent forces width', () {
      const sizing = RoadmapSizing.fixedSegmentExtent(150, crossExtent: 200);
      expect(
        sizing.resolve(
          const BoxConstraints(),
          const RoadmapGeometry(curveCount: 4),
        ),
        const Size(200, 600),
      );
    });

    test('asserts helpfully on unbounded constraints', () {
      expect(
        () => const RoadmapSizing.fitViewport().resolve(
          const BoxConstraints(),
          const RoadmapGeometry(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('RoadPath caching', () {
    test('reuses the dashed path when parameters are unchanged', () {
      final road = RoadPath.build(
        const Size(300, 600),
        const RoadmapGeometry(),
      );
      final a = road.dashed(dashWidth: 20, dashSpace: 10, upTo: road.length);
      final b = road.dashed(dashWidth: 20, dashSpace: 10, upTo: road.length);
      expect(identical(a, b), isTrue);

      final c = road.dashed(dashWidth: 8, dashSpace: 10, upTo: road.length);
      expect(identical(a, c), isFalse);
    });

    test('full-range extract returns the path itself, not a copy', () {
      // The no-progress, no-animation case repaints often; copying every
      // segment each time was pure waste.
      final road =
          RoadPath.build(const Size(300, 600), const RoadmapGeometry());
      expect(identical(road.extract(0, road.length), road.path), isTrue);
      expect(identical(road.extract(0, road.length / 2), road.path), isFalse);
    });

    test('matches() detects size and geometry changes', () {
      const size = Size(300, 600);
      const geometry = RoadmapGeometry();
      final road = RoadPath.build(size, geometry);
      expect(road.matches(size, geometry), isTrue);
      expect(road.matches(const Size(300, 601), geometry), isFalse);
      expect(road.matches(size, const RoadmapGeometry(curveCount: 3)), isFalse);
    });

    testWidgets('path is built once per size/geometry, not per frame', (
      tester,
    ) async {
      await tester.pumpWidget(
        _sized(
          const CurvedRoadmap(
            animate: true,
            markers: [
              RoadmapMarker(distanceFraction: 0.5, child: Icon(Icons.flag)),
            ],
          ),
        ),
      );

      final first = _painterOf(tester).roadPath;
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      // Same instance across animation frames: no rebuild, no recomputed
      // metrics, and markers share it rather than building their own.
      expect(identical(_painterOf(tester).roadPath, first), isTrue);

      await tester.pumpAndSettle();
    });
  });

  group('curve style equality (drives path rebuilds)', () {
    test('different waypoints are not equal', () {
      const a = WaypointCurveStyle([
        RoadWaypoint(cross: 0.2),
        RoadWaypoint(cross: 0.8),
      ]);
      const b = WaypointCurveStyle([
        RoadWaypoint(cross: 0.2),
        RoadWaypoint(cross: 0.9),
      ]);
      expect(a, isNot(equals(b)));
      expect(
        const RoadmapGeometry(curveStyle: a),
        isNot(equals(const RoadmapGeometry(curveStyle: b))),
      );
    });

    test('identical waypoints are equal', () {
      const a = WaypointCurveStyle([
        RoadWaypoint(cross: 0.2),
        RoadWaypoint(cross: 0.8),
      ]);
      const b = WaypointCurveStyle([
        RoadWaypoint(cross: 0.2),
        RoadWaypoint(cross: 0.8),
      ]);
      expect(a, equals(b));
    });
  });

  group('style copyWith', () {
    test('clears nullable fields when explicitly passed null', () {
      const style = CurvedRoadmapStyle(completedColor: Colors.red);
      expect(style.copyWith(completedColor: null).completedColor, isNull);
    });

    test('leaves nullable fields untouched when omitted', () {
      const style = CurvedRoadmapStyle(completedColor: Colors.red);
      expect(style.copyWith(roadWidth: 4).completedColor, Colors.red);
    });
  });

  group('markers', () {
    const edgeRoad = RoadmapGeometry(
      curveStyle: WaypointCurveStyle([
        RoadWaypoint(cross: 0.5),
        RoadWaypoint(cross: 0.95),
      ]),
    );

    testWidgets('renders child widgets and fires onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _sized(
          CurvedRoadmap(
            markers: [
              RoadmapMarker(
                distanceFraction: 0.5,
                onTap: () => tapped = true,
                child: const Icon(Icons.flag),
              ),
            ],
          ),
        ),
      );
      expect(find.byIcon(Icons.flag), findsOneWidget);
      await tester.tap(find.byIcon(Icons.flag));
      expect(tapped, isTrue);
    });

    testWidgets('wide content is kept inside the widget bounds', (
      tester,
    ) async {
      const key = Key('wide-marker');
      await tester.pumpWidget(
        _sized(
          const CurvedRoadmap(
            geometry: edgeRoad,
            markers: [
              RoadmapMarker(
                distanceFraction: 1.0,
                child: SizedBox(key: key, width: 250, height: 40),
              ),
            ],
          ),
        ),
      );

      final Rect roadmap = tester.getRect(find.byType(CurvedRoadmap));
      final Rect marker = tester.getRect(find.byKey(key));
      expect(marker.left, greaterThanOrEqualTo(roadmap.left - 0.5));
      expect(marker.right, lessThanOrEqualTo(roadmap.right + 0.5));
    });

    testWidgets('keepInBounds: false lets content overhang', (tester) async {
      const key = Key('overhang');
      await tester.pumpWidget(
        _sized(
          const CurvedRoadmap(
            geometry: edgeRoad,
            markers: [
              RoadmapMarker(
                distanceFraction: 1.0,
                keepInBounds: false,
                child: SizedBox(key: key, width: 250, height: 40),
              ),
            ],
          ),
        ),
      );

      final Rect roadmap = tester.getRect(find.byType(CurvedRoadmap));
      final Rect marker = tester.getRect(find.byKey(key));
      expect(
        marker.left < roadmap.left || marker.right > roadmap.right,
        isTrue,
      );
    });

    testWidgets('offset nudges the marker off the road', (tester) async {
      const plain = Key('plain');
      const nudged = Key('nudged');
      await tester.pumpWidget(
        _sized(
          const CurvedRoadmap(
            markers: [
              RoadmapMarker(
                distanceFraction: 0.5,
                child: SizedBox(key: plain, width: 20, height: 20),
              ),
              RoadmapMarker(
                distanceFraction: 0.5,
                offset: Offset(0, -40),
                child: SizedBox(key: nudged, width: 20, height: 20),
              ),
            ],
          ),
        ),
      );

      expect(
        tester.getCenter(find.byKey(nudged)).dy,
        closeTo(tester.getCenter(find.byKey(plain)).dy - 40, 0.5),
      );
    });

    testWidgets('card renders title, notes and icon', (tester) async {
      await tester.pumpWidget(
        _sized(
          CurvedRoadmap(
            markers: [
              RoadmapMarker.card(
                distanceFraction: 0.5,
                title: 'Level 1',
                notes: 'Complete the basics',
                icon: Icons.flag,
              ),
            ],
          ),
        ),
      );
      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('Complete the basics'), findsOneWidget);
      expect(find.byIcon(Icons.flag), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('tappable markers are exposed as labelled buttons', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _sized(
          CurvedRoadmap(
            markers: [
              RoadmapMarker(
                distanceFraction: 0.5,
                semanticLabel: 'Level 3',
                onTap: () {},
                child: const Icon(Icons.star),
              ),
            ],
          ),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Level 3')),
        matchesSemantics(label: 'Level 3', isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets('card markers label themselves from title and notes', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _sized(
          CurvedRoadmap(
            markers: [
              RoadmapMarker.card(
                distanceFraction: 0.5,
                title: 'Summit',
                notes: '2400m',
                onTap: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.bySemanticsLabel(RegExp('Summit')), findsWidgets);
      handle.dispose();
    });
  });

  group('painter shouldRepaint', () {
    CurvedRoadmapPainter painter({
      RoadPath? road,
      CurvedRoadmapStyle style = const CurvedRoadmapStyle(),
      double? progress,
      double reveal = 1.0,
    }) =>
        CurvedRoadmapPainter(
          roadPath: road ??
              RoadPath.build(const Size(300, 600), const RoadmapGeometry()),
          style: style,
          completedColor: Colors.blue,
          progress: progress,
          revealFraction: reveal,
        );

    test('false when nothing changed', () {
      final road = RoadPath.build(
        const Size(300, 600),
        const RoadmapGeometry(),
      );
      expect(painter(road: road).shouldRepaint(painter(road: road)), isFalse);
    });

    test('true when style, progress, reveal or path changes', () {
      final road = RoadPath.build(
        const Size(300, 600),
        const RoadmapGeometry(),
      );
      expect(
        painter(road: road).shouldRepaint(
          painter(
            road: road,
            style: const CurvedRoadmapStyle(roadColor: Colors.red),
          ),
        ),
        isTrue,
      );
      expect(
        painter(road: road).shouldRepaint(painter(road: road, progress: 0.5)),
        isTrue,
      );
      expect(
        painter(road: road).shouldRepaint(painter(road: road, reveal: 0.5)),
        isTrue,
      );
      expect(painter(road: road).shouldRepaint(painter()), isTrue);
    });
  });
}
