import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'scanner_state.dart';

class FaceOvalPainter extends CustomPainter {
  final ScannerStatus status;
  final double animationValue;

  FaceOvalPainter({required this.status, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ovalWidth = size.width * 0.75;
    final ovalHeight = size.height * 0.5;
    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    // 1. Draw Dark Mask Background
    final maskPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addOval(ovalRect),
      ),
      maskPaint,
    );

    // 2. Inset Neumorphic Effect for the Oval
    final statusColor = _getStatusColor();
    
    // Inset Shadow Simulation (Darker top-left, lighter bottom-right inside the oval)
    final shadowPaintDark = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final shadowPaintLight = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.save();
    canvas.clipPath(Path()..addOval(ovalRect));
    
    // Offset paths for inset look
    canvas.drawOval(ovalRect.shift(const Offset(2, 2)), shadowPaintDark);
    canvas.drawOval(ovalRect.shift(const Offset(-2, -2)), shadowPaintLight);
    canvas.restore();

    // 3. Circular Progress Glow (Pulse)
    if (status == ScannerStatus.scanning || status == ScannerStatus.processing) {
      final glowPaint = Paint()
        ..color = statusColor.withOpacity(0.3 * (1 - animationValue))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10 + (15 * animationValue)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      
      canvas.drawOval(ovalRect, glowPaint);
      
      // Secondary faster pulse for "AI processing" feel
      final fastPulse = (animationValue * 2) % 1.0;
      final aiPaint = Paint()
        ..color = statusColor.withOpacity(0.2 * (1 - fastPulse))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 + (8 * fastPulse);
      canvas.drawOval(ovalRect.inflate(5 * fastPulse), aiPaint);
    }

    // 4. Draw Radar Line (Scanning Effect)
    if (status == ScannerStatus.scanning || status == ScannerStatus.processing) {
      final radarPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            statusColor.withOpacity(0),
            statusColor.withOpacity(0.5),
            statusColor.withOpacity(0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(ovalRect);

      final double scanY = ovalRect.top + (ovalRect.height * animationValue);
      final double scanHeight = 20.0;
      
      final scanRect = Rect.fromLTWH(
        ovalRect.left, 
        scanY - (scanHeight / 2), 
        ovalRect.width, 
        scanHeight
      );

      // Clip radar line to oval
      canvas.save();
      canvas.clipPath(Path()..addOval(ovalRect));
      canvas.drawRect(scanRect, radarPaint);
      
      // Add a bright leading edge
      final leadPaint = Paint()
        ..color = statusColor
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(ovalRect.left, scanY), 
        Offset(ovalRect.right, scanY), 
        leadPaint
      );
      canvas.restore();
    }

    // 4. Draw Main Border
    final borderPaint = Paint()
      ..color = statusColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawOval(ovalRect, borderPaint);

    // 5. Draw Corner Guides (Techy look)
    final guidePaint = Paint()
      ..color = statusColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    const double guideLen = 40.0;
    // Top Left
    canvas.drawArc(ovalRect, pi, pi/4, false, guidePaint);
    // Top Right
    canvas.drawArc(ovalRect, -pi/2, pi/4, false, guidePaint);
    // Bottom Left
    canvas.drawArc(ovalRect, pi/2, pi/4, false, guidePaint);
    // Bottom Right
    canvas.drawArc(ovalRect, 0, pi/4, false, guidePaint);
  }

  Color _getStatusColor() {
    switch (status) {
      case ScannerStatus.scanning:
        return AppColors.primary;
      case ScannerStatus.processing:
        return AppColors.primary;
      case ScannerStatus.success:
        return AppColors.success;
      case ScannerStatus.failure:
        return AppColors.error;
      case ScannerStatus.idle:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(covariant FaceOvalPainter oldDelegate) {
    return oldDelegate.status != status || oldDelegate.animationValue != animationValue;
  }
}
