import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                else ...[
                  const _GoogleLogo(size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Standard Google logo brand colors (must remain exact standard brand colors)
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final redPaint = Paint()..color = const Color(0xFFEA4335);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.45,
      1.8,
      true,
      bluePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      1.35,
      1.0,
      true,
      greenPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.35,
      0.9,
      true,
      yellowPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.25,
      0.95,
      true,
      redPaint,
    );

    canvas.drawCircle(center, radius * 0.58, Paint()..color = Colors.white);
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx,
        center.dy - radius * 0.18,
        radius,
        radius * 0.36,
      ),
      bluePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
