import 'package:flutter/material.dart';
import 'scanner_state.dart';

class FaceOvalPainter extends CustomPainter {
  final ScannerStatus status;

  FaceOvalPainter({required this.status});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final ovalWidth = size.width * 0.7;
    final ovalHeight = size.height * 0.5;
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: ovalWidth,
      height: ovalHeight,
    );

    // Draw background with hole
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addOval(ovalRect),
      ),
      paint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = _getStatusColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawOval(ovalRect, borderPaint);
  }

  Color _getStatusColor() {
    switch (status) {
      case ScannerStatus.scanning:
        return Colors.blue.withOpacity(0.5);
      case ScannerStatus.processing:
        return Colors.blue;
      case ScannerStatus.success:
        return Colors.green;
      case ScannerStatus.failure:
        return Colors.red;
      case ScannerStatus.idle:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(covariant FaceOvalPainter oldDelegate) {
    return oldDelegate.status != status;
  }
}
