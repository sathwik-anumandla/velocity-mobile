import 'package:flutter/material.dart';

/// The '>' (angle bracket) mark for the Velocity brand logo.
class VelocityMark extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const VelocityMark({
    super.key,
    this.size = 18.0,
    this.color,
    this.strokeWidth = 2.4,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final markColor = color ?? (isDark ? Colors.white : Colors.black);

    return CustomPaint(
      size: Size(size, size),
      painter: _VelocityMarkPainter(
        color: markColor,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _VelocityMarkPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _VelocityMarkPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    // Draws '>' angle bracket mark with balanced proportions
    final left = size.width * 0.22;
    final right = size.width * 0.78;
    final top = size.height * 0.18;
    final midY = size.height * 0.50;
    final bottom = size.height * 0.82;

    path.moveTo(left, top);
    path.lineTo(right, midY);
    path.lineTo(left, bottom);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _VelocityMarkPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Brand logo row displaying the '>' mark alongside lowercase 'velocity' in Satoshi Medium.
class VelocityBrandLogo extends StatelessWidget {
  final double markSize;
  final double fontSize;
  final Color? color;

  const VelocityBrandLogo({
    super.key,
    this.markSize = 16.0,
    this.fontSize = 18.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = color ?? (isDark ? Colors.white : const Color(0xFF09090B));

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        VelocityMark(size: markSize, color: textPrimary),
        const SizedBox(width: 6),
        Text(
          'velocity',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: fontSize,
            fontWeight: FontWeight.w500, // Satoshi Medium
            color: textPrimary,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}
