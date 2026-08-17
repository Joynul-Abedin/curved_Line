import 'package:curved_roadmap/curved_roadmap.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const RoadmapExampleApp());
}

class RoadmapExampleApp extends StatelessWidget {
  const RoadmapExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'curved_roadmap demo',
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final demos = <String, WidgetBuilder>{
      'Default road': (_) => const DefaultRoadPage(),
      'Markers + progress fill': (_) => const MarkersProgressPage(),
      'Draw-in animation + gradient': (_) => const AnimatedGradientPage(),
      'Horizontal, scrollable': (_) => const HorizontalScrollablePage(),
      'Curve style variants': (_) => const CurveVariantsPage(),
      'Theme-extension styling': (_) => const ThemeExtensionPage(),
      'Full manual control (waypoints)': (_) => const WaypointDemoPage(),
      'Rich marker cards (image/title/notes)': (_) => const RichMarkersPage(),
      'Place anywhere, any length': (_) => const PlacementPage(),
      'Serpentine infographic (numbered)': (_) => const SerpentinePage(),
      'Serpentine with map pins': (_) => const SerpentinePinsPage(),
      'Captions beside the road': (_) => const SideCaptionsPage(),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('curved_roadmap examples')),
      body: ListView(
        children: demos.entries
            .map(
              (entry) => ListTile(
                title: Text(entry.key),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: entry.value)),
              ),
            )
            .toList(),
      ),
    );
  }
}

class DefaultRoadPage extends StatelessWidget {
  const DefaultRoadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Default road')),
      body: const CurvedRoadmap(backgroundColor: Colors.green),
    );
  }
}

class MarkersProgressPage extends StatefulWidget {
  const MarkersProgressPage({super.key});

  @override
  State<MarkersProgressPage> createState() => _MarkersProgressPageState();
}

class _MarkersProgressPageState extends State<MarkersProgressPage> {
  double _progress = 0.4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Markers + progress fill')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Slider(
              value: _progress,
              onChanged: (v) => setState(() => _progress = v),
              label: '${(_progress * 100).round()}% complete',
            ),
          ),
          Expanded(
            child: CurvedRoadmap(
              backgroundColor: Colors.green.shade50,
              geometry: const RoadmapGeometry(curveCount: 3),
              progress: _progress,
              style: const CurvedRoadmapStyle(completedColor: Colors.orange),
              markers: [
                for (int i = 1; i <= 5; i++)
                  RoadmapMarker(
                    distanceFraction: i / 6,
                    onTap: () => ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Level $i tapped'))),
                    child: CircleAvatar(
                      backgroundColor:
                          (i / 6) <= _progress ? Colors.orange : Colors.grey,
                      child: Text('$i'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedGradientPage extends StatelessWidget {
  const AnimatedGradientPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Draw-in animation + gradient')),
      body: CurvedRoadmap(
        backgroundColor: Colors.blueGrey.shade50,
        animate: true,
        animationDuration: const Duration(seconds: 2),
        geometry: const RoadmapGeometry(curveCount: 3),
        style: const CurvedRoadmapStyle(
          roadWidth: 24,
          roadGradient: LinearGradient(
            colors: [Colors.purple, Colors.pink, Colors.orange],
          ),
        ),
      ),
    );
  }
}

class HorizontalScrollablePage extends StatelessWidget {
  const HorizontalScrollablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Horizontal, scrollable')),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: CurvedRoadmap(
          backgroundColor: Colors.green.shade50,
          geometry: const RoadmapGeometry(
            orientation: RoadmapOrientation.horizontal,
            curveCount: 8,
          ),
          sizing: const RoadmapSizing.fixedSegmentExtent(260),
        ),
      ),
    );
  }
}

class CurveVariantsPage extends StatefulWidget {
  const CurveVariantsPage({super.key});

  @override
  State<CurveVariantsPage> createState() => _CurveVariantsPageState();
}

class _CurveVariantsPageState extends State<CurveVariantsPage> {
  final Map<String, RoadCurveStyle> _variants = const {
    'S-curve': SCurveStyle(),
    'Zigzag': ZigzagCurveStyle(),
    'Sine': SineCurveStyle(),
    'Straight': StraightCurveStyle(),
  };
  String _selected = 'S-curve';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Curve style variants')),
      body: Column(
        children: [
          Wrap(
            spacing: 8,
            children: _variants.keys
                .map(
                  (name) => ChoiceChip(
                    label: Text(name),
                    selected: _selected == name,
                    onSelected: (_) => setState(() => _selected = name),
                  ),
                )
                .toList(),
          ),
          Expanded(
            child: CurvedRoadmap(
              backgroundColor: Colors.green.shade50,
              geometry: RoadmapGeometry(
                curveCount: 3,
                curveStyle: _variants[_selected]!,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ThemeExtensionPage extends StatelessWidget {
  const ThemeExtensionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        extensions: const [
          CurvedRoadmapStyle(roadColor: Colors.brown, lineColor: Colors.amber),
        ],
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Theme-extension styling')),
        // No `style` passed — CurvedRoadmap picks it up from the Theme.
        body: const CurvedRoadmap(backgroundColor: Colors.green),
      ),
    );
  }
}

/// Every turn placed by hand — arbitrary cross position and smooth/sharp
/// per turn, via [WaypointCurveStyle], instead of a uniform preset.
class WaypointDemoPage extends StatelessWidget {
  const WaypointDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Full manual control (waypoints)')),
      body: CurvedRoadmap(
        backgroundColor: Colors.green.shade50,
        style: const CurvedRoadmapStyle(roadColor: Colors.indigo),
        geometry: const RoadmapGeometry(
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
    );
  }
}

/// Markers built from [RoadmapMarker.card] — title, notes, and an
/// image/icon, without hand-building a layout.
class RichMarkersPage extends StatelessWidget {
  const RichMarkersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rich marker cards')),
      body: CurvedRoadmap(
        backgroundColor: Colors.green.shade50,
        geometry: const RoadmapGeometry(curveCount: 3),
        markers: [
          RoadmapMarker.card(
            distanceFraction: 0.15,
            title: 'Trailhead',
            notes: 'Start here',
            icon: Icons.flag,
            onTap: () => _showSnack(context, 'Trailhead tapped'),
          ),
          RoadmapMarker.card(
            distanceFraction: 0.45,
            title: 'Rest stop',
            notes: 'Great photo spot',
            image: const Icon(Icons.landscape, color: Colors.white),
            color: Colors.teal,
            onTap: () => _showSnack(context, 'Rest stop tapped'),
          ),
          RoadmapMarker.card(
            distanceFraction: 0.8,
            title: 'Summit',
            notes: '2,400m — bring water',
            icon: Icons.terrain,
            color: Colors.deepOrange,
            onTap: () => _showSnack(context, 'Summit tapped'),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// The road placed at arbitrary positions and lengths — inside a small card,
/// in a row beside other content, and confined to part of its box via
/// `alongStart`/`alongEnd`.
class PlacementPage extends StatelessWidget {
  const PlacementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Place anywhere, any length')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Inside a small card'),
          const SizedBox(height: 8),
          Card(
            child: SizedBox(
              height: 180,
              child: CurvedRoadmap(
                style: const CurvedRoadmapStyle(
                  roadWidth: 10,
                  dashWidth: 8,
                  dashSpace: 5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Top half only (alongStart 0.5 → alongEnd 0.0)'),
          const SizedBox(height: 8),
          Container(
            height: 240,
            color: Colors.green.shade50,
            child: const CurvedRoadmap(
              geometry: RoadmapGeometry(
                alongStart: 0.5,
                alongEnd: 0.0,
                curveCount: 1,
              ),
              style: CurvedRoadmapStyle(roadWidth: 12),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Beside other content, fixed width'),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                const SizedBox(
                  width: 120,
                  child: CurvedRoadmap(
                    geometry: RoadmapGeometry(curveCount: 3),
                    style: CurvedRoadmapStyle(roadWidth: 10),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    color: Colors.blueGrey.shade50,
                    alignment: Alignment.center,
                    child: const Text('Other content sits here'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Many turns still fit exactly (curveCount: 12)'),
          const SizedBox(height: 8),
          Container(
            height: 300,
            color: Colors.green.shade50,
            child: const CurvedRoadmap(
              geometry: RoadmapGeometry(curveCount: 12, curveAmplitude: 0.4),
              style: CurvedRoadmapStyle(
                roadWidth: 8,
                lineStyle: RoadLineStyle.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The printed-infographic layout: a serpentine road with numbered
/// milestones and captions, START/FINISH end caps.
class SerpentinePage extends StatelessWidget {
  const SerpentinePage({super.key});

  static const _steps = <String, String>{
    '1': 'Discovery',
    '2': 'Design',
    '3': 'Build',
    '4': 'Test',
    '5': 'Beta',
    '6': 'Launch',
  };

  static const _colors = <Color>[
    Color(0xFF8BC34A),
    Color(0xFF4DB6AC),
    Color(0xFF4FC3F7),
    Color(0xFF5C6BC0),
    Color(0xFF7E57C2),
    Color(0xFFEC407A),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = _steps.entries.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Serpentine infographic')),
      // This layout is inherently wide — the same as the printed
      // infographics it mimics — so give it room and let it scroll.
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1150,
          child: CurvedRoadmap(
            backgroundColor: const Color(0xFFFAFAFA),
            geometry: const RoadmapGeometry(
              curveStyle: SerpentineCurveStyle(rows: 3),
              curveAmplitude: 0.44,
            ),
            style: const CurvedRoadmapStyle(
              roadColor: Color(0xFF2E2E2E),
              roadWidth: 26,
              borderColor: Color(0xFFBDBDBD),
              borderWidth: 3,
              dashWidth: 16,
              dashSpace: 12,
            ),
            markers: [
              RoadmapMarker.milestone(
                distanceFraction: 0,
                label: 'START',
                color: const Color(0xFF8BC34A),
                diameter: 104,
              ),
              for (int i = 0; i < entries.length; i++)
                RoadmapMarker.milestone(
                  distanceFraction: (i + 1) / (entries.length + 1),
                  label: entries[i].key,
                  title: entries[i].value.toUpperCase(),
                  body: 'Lorem ipsum dolor sit amet, consectetuer '
                      'adipiscing elit, sed diam nonummy.',
                  color: _colors[i % _colors.length],
                  captionWidth: 170,
                ),
              RoadmapMarker.milestone(
                distanceFraction: 1,
                label: 'FINISH',
                color: const Color(0xFFE53935),
                diameter: 104,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The slide-deck layout: the same serpentine road, with teardrop map pins
/// whose tips rest on the path.
class SerpentinePinsPage extends StatelessWidget {
  const SerpentinePinsPage({super.key});

  static const _colors = <Color>[
    Color(0xFFFFC107),
    Color(0xFFE53935),
    Color(0xFF8E24AA),
    Color(0xFF1E88E5),
    Color(0xFFFDD835),
    Color(0xFF00897B),
    Color(0xFF7CB342),
    Color(0xFF37474F),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Serpentine with map pins')),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1000,
          child: CurvedRoadmap(
            backgroundColor: Colors.white,
            geometry: const RoadmapGeometry(
              curveStyle: SerpentineCurveStyle(rows: 4),
              curveAmplitude: 0.42,
            ),
            style: const CurvedRoadmapStyle(
              roadColor: Color(0xFF757575),
              roadWidth: 30,
              borderColor: Color(0xFFD6D6D6),
              borderWidth: 8,
              lineColor: Colors.white,
              dashWidth: 14,
              dashSpace: 10,
            ),
            markers: [
              for (int i = 0; i < 8; i++)
                RoadmapMarker.pin(
                  distanceFraction: (i + 0.5) / 8,
                  label: '0${i + 1}',
                  color: _colors[i],
                  size: 46,
                  onTap: () => ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Step 0${i + 1}'))),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Captions placed clear of the road, alternating sides — the layout most
/// slide-deck roadmap templates use. `RoadSide` follows the road's own
/// direction, so the captions stay square to the tarmac as it winds.
class SideCaptionsPage extends StatefulWidget {
  const SideCaptionsPage({super.key});

  @override
  State<SideCaptionsPage> createState() => _SideCaptionsPageState();
}

class _SideCaptionsPageState extends State<SideCaptionsPage> {
  RoadSide _side = RoadSide.alternating;

  static const _steps = <(String, String)>[
    ('2017', 'Kicked the project off'),
    ('2018', 'Shipped the first release'),
    ('2019', 'Grew the team'),
    ('2020', 'Went international'),
  ];

  static const _colors = <Color>[
    Color(0xFF00897B),
    Color(0xFFF5A623),
    Color(0xFF7ED321),
    Color(0xFF4A90D9),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Captions beside the road')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: RoadSide.values
                  .map(
                    (side) => ChoiceChip(
                      label: Text(side.name),
                      selected: _side == side,
                      onSelected: (_) => setState(() => _side = side),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: CurvedRoadmap(
              backgroundColor: Colors.white,
              geometry: const RoadmapGeometry(curveCount: 2),
              style: const CurvedRoadmapStyle(
                roadColor: Color(0xFF4A4A4A),
                roadWidth: 34,
                lineColor: Colors.white,
                dashWidth: 14,
                dashSpace: 12,
              ),
              markers: [
                for (int i = 0; i < _steps.length; i++) ...[
                  RoadmapMarker.pin(
                    distanceFraction: (i + 0.5) / _steps.length,
                    label: '',
                    color: _colors[i],
                    size: 34,
                  ),
                  RoadmapMarker(
                    distanceFraction: (i + 0.5) / _steps.length,
                    side: _side,
                    sideOffset: 26,
                    semanticLabel: '${_steps[i].$1}. ${_steps[i].$2}',
                    child: _Caption(
                      year: _steps[i].$1,
                      text: _steps[i].$2,
                      color: _colors[i],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.year, required this.text, required this.color});

  final String year;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            year,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.black87),
          ),
          Container(height: 3, width: 60, color: color),
          const SizedBox(height: 6),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
