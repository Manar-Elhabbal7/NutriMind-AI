import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
