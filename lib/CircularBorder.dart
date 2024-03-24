import 'dart:math';
import 'package:flutter/material.dart';

class CircularBorder extends StatelessWidget {
  final Color color;
  final double size; // Size of the circular border in pixels
  final double lineWidth;
  final int numberOfLines;
  final double lineLength;
  final Widget? centerWidget;
  final double centerWidgetSize;
  final double newLineAngle; // Angle for the new line in degrees
  final Color newLineColor; // Color of the new line

  const CircularBorder({
    Key? key,
    this.color = Colors.blue,
    this.size = 200.0, // Default size: 100 pixels
    this.lineWidth = 1.0,
    this.numberOfLines = 36,
    this.lineLength = 8.0,
    this.centerWidget,
    required this.centerWidgetSize,
    required this.newLineAngle,
    required this.newLineColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (centerWidget != null)
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: centerWidgetSize,
                maxHeight: centerWidgetSize,
              ),
              child: centerWidget,
            ),
          ),
        Center(
          child: CustomPaint(
            size: Size(size, size),
            painter: _CircularBorderPainter(
              color: color,
              lineWidth: lineWidth,
              numberOfLines: numberOfLines,
              lineLength: lineLength,
              centerWidgetSize: 0,
              newLineAngle: newLineAngle,
              newLineColor: newLineColor,
            ),
          ),
        )
      ],
    );
  }
}

class _CircularBorderPainter extends CustomPainter {
  final Color color;
  final double lineWidth;
  final int numberOfLines;
  final double lineLength;
  final double centerWidgetSize;
  final double newLineAngle;
  final Color newLineColor;

  _CircularBorderPainter({
    required this.color,
    required this.lineWidth,
    required this.numberOfLines,
    required this.lineLength,
    required this.centerWidgetSize,
    required this.newLineAngle,
    required this.newLineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = lineWidth;

    final Paint newLinePaint = Paint()
      ..color = newLineColor // Color for the new line
      ..strokeWidth = lineWidth;

    final double radius = min(size.width / 2, size.height / 2);
    final double angleStep = 2 * pi / numberOfLines;

    final double adjustedRadius = radius - centerWidgetSize / 2;

    for (int i = 0; i < numberOfLines; i++) {
      final double angle = i * angleStep + pi / 2;

      final Offset startPoint = Offset(
        (size.width / 2) + (adjustedRadius * cos(angle)),
        (size.height / 2) + (adjustedRadius * sin(angle)),
      );

      final Offset endPoint = Offset(
        (size.width / 2) + ((adjustedRadius - lineLength) * cos(angle)),
        (size.height / 2) + ((adjustedRadius - lineLength) * sin(angle)),
      );

      if ((angle * 180 / pi) + 90 == newLineAngle) {
        canvas.drawLine(
            startPoint, endPoint, newLinePaint); // Draw the new line
      } else {
        canvas.drawLine(startPoint, endPoint, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
