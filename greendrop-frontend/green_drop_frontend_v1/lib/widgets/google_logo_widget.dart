import 'package:flutter/material.dart';

class GoogleLogoWidget extends StatelessWidget {
  final double size;
  const GoogleLogoWidget({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final double strokeWidth = size.width * 0.22;

    final Paint redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint blueFillPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final Rect rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Draw Google 4-color 'G' arcs
    // Red arc (Top)
    canvas.drawArc(rect, -3.14159 * 0.75, 3.14159 * 0.65, false, redPaint);
    // Yellow arc (Bottom Left)
    canvas.drawArc(rect, 3.14159 * 0.65, 3.14159 * 0.45, false, yellowPaint);
    // Green arc (Bottom Right)
    canvas.drawArc(rect, 3.14159 * 0.15, 3.14159 * 0.45, false, greenPaint);
    // Blue arc (Right)
    canvas.drawArc(rect, -3.14159 * 0.3, 3.14159 * 0.4, false, bluePaint);

    // Horizontal bar for 'G'
    final Rect barRect = Rect.fromLTWH(
      center.dx - strokeWidth * 0.1,
      center.dy - strokeWidth / 2.2,
      radius * 0.85,
      strokeWidth * 0.9,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(2)),
      blueFillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
