import 'dart:ui';

import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
      debugShowCheckedModeBanner: false, home: Scaffold(body: RoadMap())));
}

class RoadMap extends StatelessWidget {
  const RoadMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          color: Colors.green,
          child: CustomPaint(
            painter: RoadPainter(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
            ),
          ),
        ),
      ],
    );
  }
}

class RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const roadWidth = 20.0; // Set the road width
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = roadWidth;

    // Start the road path
    final path = Path()..moveTo(size.width * 0.05, size.height * 0.95);

    const workingXForUpLeft = 0.95;
    var workingYForUpLeft = 0.95;
    const workingWidthForUpLeft = 0.95;
    var workingHeightForUpLeft = 0.9;

    const workingXForUpRight = 0.05;
    var workingYForUpRight = 0.85;
    const workingWidthForUpRight = 0.05;
    var workingHeightForUpRight = 0.8;

    for (int i = 0; i < 2; i++) {
      upLeftCurve(path, size, workingXForUpLeft, workingYForUpLeft,
          workingWidthForUpLeft, workingHeightForUpLeft);
      upRightCurve(path, size, workingXForUpRight, workingYForUpRight,
          workingWidthForUpRight, workingHeightForUpRight);
      workingYForUpLeft -= 0.2;
      workingHeightForUpLeft -= 0.2;
      workingYForUpRight -= 0.2;
      workingHeightForUpRight -= 0.2;
    }

    // upLeftCurve(path, size, 0.95, 0.95, 0.95, 0.9);
    //
    // upRightCurve(path, size, 0.05, 0.85, 0.05, 0.8);
    //
    // upLeftCurve(path, size, 0.95, 0.75, 0.95, 0.7);
    //
    // upRightCurve(path, size, 0.05, 0.65, 0.05, 0.6);
    //
    // upLeftCurve(path, size, 0.95, 0.55, 0.95, 0.5);
    //
    // upRightCurve(path, size, 0.05, 0.45, 0.05, 0.4);
    //
    // upLeftCurve(path, size, 0.95, 0.35, 0.95, 0.3);
    //
    // upRightCurve(path, size, 0.05, 0.25, 0.05, 0.2);

    // Draw the road
    canvas.drawPath(path, paint);

    // Now create the dashed line paint
    final dashedPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          roadWidth / 10; // Adjust the width of the dashed line as needed

    // Drawing the dashed lines on the road
    double dashWidth = 20.0;
    double dashSpace = 10.0;
    double distance = 0.0;
    final PathMetrics pathMetrics = path.computeMetrics();
    for (final PathMetric metric in pathMetrics) {
      while (distance < metric.length) {
        final Path extractPath =
            metric.extractPath(distance, distance + dashWidth);
        canvas.drawPath(extractPath, dashedPaint);
        distance += dashWidth + dashSpace;
      }
      distance = 0.0; // Reset the distance for the next path metric
    }
  }

  upLeftCurve(
      Path path, Size size, double x, double y, double width, double height) {
    path.quadraticBezierTo(
      size.width * x,
      size.height * y, // control point for the curve to the right
      size.width * width, size.height * height, // end point of the curve
    );

    path.quadraticBezierTo(
      size.width * x,
      size.height * (y - 0.10), // control point for the curve to the right
      size.width / 2, size.height * (height - 0.05), // end point of the curve
    );
  }

  upRightCurve(
      Path path, Size size, double x, double y, double width, double height) {
    path.quadraticBezierTo(
      size.width * x,
      size.height * y, // control point for the curve to the right
      size.width * width, size.height * height, // end point of the curve
    );

    path.quadraticBezierTo(
      size.width * x,
      size.height * (y - 0.10), // control point for the curve to the right
      size.width / 2, size.height * (height - 0.05), // end point of the curve
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
