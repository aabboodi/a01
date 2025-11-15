import 'package:flutter/material.dart';

// Represents a single continuous line drawn on the whiteboard.
class DrawingLine {
  final Color color;
  final double strokeWidth;
  final List<Offset> points;

  DrawingLine({
    required this.color,
    required this.strokeWidth,
    required this.points,
  });
}

// CustomPainter to draw the lines on the canvas.
class WhiteboardPainter extends CustomPainter {
  final List<DrawingLine> lines;

  WhiteboardPainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final line in lines) {
      paint.color = line.color;
      paint.strokeWidth = line.strokeWidth;

      // Draw a line connecting all points.
      if (line.points.isNotEmpty) {
        final path = Path();
        path.moveTo(line.points.first.dx, line.points.first.dy);
        for (var i = 1; i < line.points.length; i++) {
          path.lineTo(line.points[i].dx, line.points[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WhiteboardPainter oldDelegate) {
    // Repaint whenever the lines change.
    return oldDelegate.lines != lines;
  }
}
