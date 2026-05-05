import 'package:flutter/material.dart';
import '../theme.dart';

class Logo extends StatelessWidget {
  final double size;
  final bool showText;

  const Logo({
    super.key,
    this.size = 60,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Geometric Face Icon (Custom painted or using Icons with styling)
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(size * 0.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Geometric eyes
              Positioned(
                top: size * 0.3,
                left: size * 0.2,
                child: Container(
                  width: size * 0.2,
                  height: size * 0.1,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Positioned(
                top: size * 0.3,
                right: size * 0.2,
                child: Container(
                  width: size * 0.2,
                  height: size * 0.1,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Geometric mouth/line
              Positioned(
                bottom: size * 0.25,
                left: size * 0.3,
                right: size * 0.3,
                child: Container(
                  height: size * 0.05,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              // Scan line effect
              Positioned(
                top: size * 0.45,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 12),
          Text(
            'I-POINTEO',
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              letterSpacing: 2,
            ),
          ),
        ],
      ],
    );
  }
}
