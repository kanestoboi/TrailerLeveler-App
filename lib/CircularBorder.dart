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

  const CircularBorder({
    Key? key,
    this.color = Colors.blue,
    this.size = 200.0, // Default size: 100 pixels
    this.lineWidth = 1.0,
    this.numberOfLines = 36,
    this.lineLength = 8.0,
    this.centerWidget,
    required this.centerWidgetSize,
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
                  maxHeight: centerWidgetSize), // Set maximum width and height
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

  _CircularBorderPainter({
    required this.color,
    required this.lineWidth,
    required this.numberOfLines,
    required this.lineLength,
    required this.centerWidgetSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = lineWidth;

    final double radius = min(size.width / 2, size.height / 2);
    final double angleStep = 2 * pi / numberOfLines;

    final double adjustedRadius = radius - centerWidgetSize / 2;

    for (int i = 0; i < numberOfLines; i++) {
      final double angle =
          i * angleStep + pi / 2; // Offset the starting angle by pi / 2

      final Offset startPoint = Offset(
        (size.width / 2) + (adjustedRadius * cos(angle)),
        (size.height / 2) + (adjustedRadius * sin(angle)),
      );

      final Offset endPoint = Offset(
        (size.width / 2) + ((adjustedRadius - lineLength) * cos(angle)),
        (size.height / 2) + ((adjustedRadius - lineLength) * sin(angle)),
      );

      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
