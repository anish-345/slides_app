import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/slide_element.dart';

class ShapeElementView extends StatelessWidget {
  final SlideElement element;
  final double scale;

  const ShapeElementView({
    super.key,
    required this.element,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(element.width * scale, element.height * scale),
      painter: _ShapePainter(
        shapeType: element.shapeType.toLowerCase(),
        fillColor: Color(element.fillColor),
        strokeColor: Color(element.strokeColor),
        strokeWidth: element.strokeWidth * scale,
        borderRadius: element.borderRadius * scale,
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  final String shapeType;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final double borderRadius;

  _ShapePainter({
    required this.shapeType,
    required this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    switch (shapeType) {
      case 'circle':
        canvas.drawOval(rect, fillPaint);
        if (strokeWidth > 0) canvas.drawOval(rect, strokePaint);
        break;

      case 'rounded_rect':
      case 'roundedrect':
        final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius > 0 ? borderRadius : 8));
        canvas.drawRRect(rrect, fillPaint);
        if (strokeWidth > 0) canvas.drawRRect(rrect, strokePaint);
        break;

      case 'triangle':
        final path = Path()
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(path, fillPaint);
        if (strokeWidth > 0) canvas.drawPath(path, strokePaint);
        break;

      case 'arrow':
      case 'arrow_right':
      case 'arrowright':
        final path = Path();
        final stemHeight = size.height * 0.4;
        final stemTop = (size.height - stemHeight) / 2;
        final headStart = size.width * 0.65;

        path.moveTo(0, stemTop);
        path.lineTo(headStart, stemTop);
        path.lineTo(headStart, 0);
        path.lineTo(size.width, size.height / 2);
        path.lineTo(headStart, size.height);
        path.lineTo(headStart, stemTop + stemHeight);
        path.lineTo(0, stemTop + stemHeight);
        path.close();

        canvas.drawPath(path, fillPaint);
        if (strokeWidth > 0) canvas.drawPath(path, strokePaint);
        break;

      case 'star':
        final path = Path();
        final cx = size.width / 2;
        final cy = size.height / 2;
        final outerR = math.min(size.width, size.height) / 2;
        final innerR = outerR * 0.45;
        const int points = 5;

        for (int i = 0; i < points * 2; i++) {
          final r = i.isEven ? outerR : innerR;
          final angle = (i * math.pi / points) - (math.pi / 2);
          final x = cx + r * math.cos(angle);
          final y = cy + r * math.sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();

        canvas.drawPath(path, fillPaint);
        if (strokeWidth > 0) canvas.drawPath(path, strokePaint);
        break;

      case 'rectangle':
      default:
        canvas.drawRect(rect, fillPaint);
        if (strokeWidth > 0) canvas.drawRect(rect, strokePaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ShapePainter oldDelegate) {
    return oldDelegate.shapeType != shapeType ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}
