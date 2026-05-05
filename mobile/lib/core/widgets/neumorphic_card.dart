import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter/material.dart' as material;
import '../theme.dart';

class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final bool isInset;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 16,
    this.backgroundColor,
    this.isInset = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.accent;

    if (isInset) {
      return Container(
        margin: margin,
        child: CustomPaint(
          painter: _NeumorphicInsetPainter(
            borderRadius: borderRadius,
            backgroundColor: bgColor,
          ),
          child: Container(
            padding: padding,
            child: child,
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      padding: padding,
      decoration: material.BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          // Raised shadow (Top-left)
          material.BoxShadow(
            color: Colors.white,
            offset: const Offset(-4, -4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
          // Dark shadow (Bottom-right)
          material.BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(4, 4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _NeumorphicInsetPainter extends CustomPainter {
  final double borderRadius;
  final Color backgroundColor;

  _NeumorphicInsetPainter({
    required this.borderRadius,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // 1. Draw background
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRRect(rrect, bgPaint);

    // 2. Draw Inset Shadows
    final shadowPaintDark = Paint()
      ..color = Colors.grey.shade400
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final shadowPaintLight = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.save();
    canvas.clipRRect(rrect);

    // Dark shadow (Top-left)
    canvas.drawRRect(rrect.shift(const Offset(2, 2)), shadowPaintDark);
    // Light shadow (Bottom-right)
    canvas.drawRRect(rrect.shift(const Offset(-2, -2)), shadowPaintLight);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NeumorphicInsetPainter oldDelegate) => false;
}
