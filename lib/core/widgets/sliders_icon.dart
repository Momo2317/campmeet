import 'package:flutter/widgets.dart';

/// Zwei Linien mit je einem Kreis (oben rechts, unten links) – Filter-Icon.
class SlidersIcon extends StatelessWidget {
  const SlidersIcon({super.key, required this.color, this.size = 24});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _SlidersPainter(color),
    );
  }
}

class _SlidersPainter extends CustomPainter {
  _SlidersPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.085
      ..strokeCap = StrokeCap.round;
    final r = w * 0.14;
    final y1 = w * 0.32;
    final y2 = w * 0.68;
    final x1 = w * 0.68; // Kreis oben rechts
    final x2 = w * 0.32; // Kreis unten links
    final l = w * 0.1;
    final rr = w * 0.9;
    canvas.drawLine(Offset(l, y1), Offset(x1 - r, y1), paint);
    canvas.drawLine(Offset(x1 + r, y1), Offset(rr, y1), paint);
    canvas.drawLine(Offset(l, y2), Offset(x2 - r, y2), paint);
    canvas.drawLine(Offset(x2 + r, y2), Offset(rr, y2), paint);
    canvas.drawCircle(Offset(x1, y1), r, paint);
    canvas.drawCircle(Offset(x2, y2), r, paint);
  }

  @override
  bool shouldRepaint(_SlidersPainter old) => old.color != color;
}
