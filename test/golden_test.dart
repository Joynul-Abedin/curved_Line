@Tags(['golden'])
library;

import 'package:curved_roadmap/curved_roadmap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden tests: the actual regression net for a package whose job is pixels.
/// The geometry tests assert the math; these assert what lands on screen.
///
/// Regenerate after an intentional visual change:
///   flutter test --update-goldens
///
/// Golden images depend on the host platform and engine version, so CI on a
/// non-reference platform should skip them:
///   flutter test --exclude-tags golden
Widget _frame(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFE8F5E9),
        body: Center(child: SizedBox(width: 300, height: 600, child: child)),
      ),
    );

void main() {
  testWidgets('default road', (tester) async {
    await tester.pumpWidget(_frame(const CurvedRoadmap()));
    await expectLater(
      find.byType(CurvedRoadmap),
      matchesGoldenFile('goldens/default_road.png'),
    );
  });

  testWidgets('solid centerline, thick road', (tester) async {
    await tester.pumpWidget(
      _frame(
        const CurvedRoadmap(
          style: CurvedRoadmapStyle(
            roadColor: Color(0xFF5D4037),
            roadWidth: 28,
            lineColor: Color(0xFFFFC107),
            lineStyle: RoadLineStyle.solid,
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(CurvedRoadmap),
      matchesGoldenFile('goldens/solid_line.png'),
    );
  });

  testWidgets('progress fill', (tester) async {
    await tester.pumpWidget(
      _frame(
        const CurvedRoadmap(
          progress: 0.4,
          style: CurvedRoadmapStyle(completedColor: Color(0xFFFF9800)),
          geometry: RoadmapGeometry(curveCount: 3),
        ),
      ),
    );
    await expectLater(
      find.byType(CurvedRoadmap),
      matchesGoldenFile('goldens/progress_fill.png'),
    );
  });

  testWidgets('gradient stroke composes with progress', (tester) async {
    await tester.pumpWidget(
      _frame(
        const CurvedRoadmap(
          progress: 0.35,
          style: CurvedRoadmapStyle(
            roadGradient: LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFFFF9800)],
            ),
            completedColor: Color(0xFF4CAF50),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(CurvedRoadmap),
      matchesGoldenFile('goldens/gradient_progress.png'),
    );
  });

  testWidgets('curve style variants', (tester) async {
    for (final entry in const <String, RoadCurveStyle>{
      'zigzag': ZigzagCurveStyle(),
      'sine': SineCurveStyle(),
      'straight': StraightCurveStyle(),
    }.entries) {
      await tester.pumpWidget(
        _frame(
          CurvedRoadmap(
            geometry: RoadmapGeometry(curveCount: 3, curveStyle: entry.value),
          ),
        ),
      );
      await expectLater(
        find.byType(CurvedRoadmap),
        matchesGoldenFile('goldens/curve_${entry.key}.png'),
      );
    }
  });

  testWidgets('waypoint road with mixed smooth and sharp turns', (
    tester,
  ) async {
    await tester.pumpWidget(
      _frame(
        const CurvedRoadmap(
          style: CurvedRoadmapStyle(roadColor: Color(0xFF3F51B5)),
          geometry: RoadmapGeometry(
            curveStyle: WaypointCurveStyle([
              RoadWaypoint(cross: 0.15),
              RoadWaypoint(cross: 0.85),
              RoadWaypoint(cross: 0.3, turn: RoadTurnType.sharp),
              RoadWaypoint(cross: 0.9),
              RoadWaypoint(cross: 0.1, turn: RoadTurnType.sharp),
              RoadWaypoint(cross: 0.6),
            ]),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(CurvedRoadmap),
      matchesGoldenFile('goldens/waypoints.png'),
    );
  });

  testWidgets('many turns still fit the box', (tester) async {
    await tester.pumpWidget(
      _frame(
        const CurvedRoadmap(
          geometry: RoadmapGeometry(curveCount: 12, curveAmplitude: 0.4),
          style: CurvedRoadmapStyle(
            roadWidth: 8,
            lineStyle: RoadLineStyle.none,
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(CurvedRoadmap),
      matchesGoldenFile('goldens/many_turns.png'),
    );
  });

  testWidgets('partial extent leaves the rest of the box empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      _frame(
        const CurvedRoadmap(
          geometry: RoadmapGeometry(
            alongStart: 0.5,
            alongEnd: 0.0,
            curveCount: 1,
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(CurvedRoadmap),
      matchesGoldenFile('goldens/partial_extent.png'),
    );
  });

  testWidgets('serpentine road with numbered milestones', (tester) async {
    await tester.pumpWidget(
      _frame(
        CurvedRoadmap(
          geometry: const RoadmapGeometry(
            curveStyle: SerpentineCurveStyle(rows: 3),
            curveAmplitude: 0.42,
          ),
          style: const CurvedRoadmapStyle(
            roadColor: Color(0xFF2E2E2E),
            roadWidth: 22,
            borderColor: Color(0xFFBDBDBD),
            borderWidth: 3,
          ),
          markers: [
            RoadmapMarker.milestone(distanceFraction: 0, label: 'S'),
            RoadmapMarker.milestone(
              distanceFraction: 0.5,
              label: '1',
              title: 'DESIGN',
            ),
            RoadmapMarker.milestone(distanceFraction: 1, label: 'F'),
          ],
        ),
      ),
    );
    await expectLater(
      find.byType(CurvedRoadmap),
      matchesGoldenFile('goldens/serpentine_milestones.png'),
    );
  });

  testWidgets('serpentine road with map pins', (tester) async {
    await tester.pumpWidget(
      _frame(
        CurvedRoadmap(
          geometry: const RoadmapGeometry(
            curveStyle: SerpentineCurveStyle(rows: 4),
          ),
          style: const CurvedRoadmapStyle(
            roadColor: Color(0xFF757575),
            roadWidth: 26,
            borderColor: Color(0xFFD6D6D6),
            borderWidth: 7,
          ),
          markers: [
            for (int i = 0; i < 6; i++)
              RoadmapMarker.pin(
                distanceFraction: (i + 0.5) / 6,
                label: '0${i + 1}',
              ),
          ],
        ),
      ),
    );
    await expectLater(
      find.byType(CurvedRoadmap),
      matchesGoldenFile('goldens/serpentine_pins.png'),
    );
  });

  testWidgets('captions alternating either side of the road', (tester) async {
    await tester.pumpWidget(
      _frame(
        CurvedRoadmap(
          style: const CurvedRoadmapStyle(roadWidth: 26),
          markers: [
            for (int i = 0; i < 4; i++) ...[
              RoadmapMarker.pin(
                distanceFraction: (i + 0.5) / 4,
                label: '',
                size: 26,
              ),
              RoadmapMarker(
                distanceFraction: (i + 0.5) / 4,
                side: RoadSide.alternating,
                sideOffset: 14,
                child: Container(
                  width: 70,
                  height: 26,
                  color: const Color(0xFF4A90D9),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    await expectLater(
      find.byType(CurvedRoadmap),
      matchesGoldenFile('goldens/side_captions.png'),
    );
  });

  testWidgets('markers near the edge stay inside the bounds', (tester) async {
    await tester.pumpWidget(
      _frame(
        CurvedRoadmap(
          geometry: const RoadmapGeometry(curveCount: 3),
          markers: [
            RoadmapMarker.card(
              distanceFraction: 0.15,
              title: 'Trailhead',
              notes: 'Start here',
            ),
            RoadmapMarker.card(
              distanceFraction: 0.5,
              title: 'Rest stop',
              notes: 'Photo spot',
            ),
            RoadmapMarker.card(
              distanceFraction: 0.85,
              title: 'Summit',
              notes: '2,400m',
            ),
          ],
        ),
      ),
    );
    await expectLater(
      find.byType(CurvedRoadmap),
      matchesGoldenFile('goldens/markers_in_bounds.png'),
    );
  });
}
