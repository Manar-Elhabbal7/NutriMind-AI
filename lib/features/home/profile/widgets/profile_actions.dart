import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ProfileActions extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSaveChanges;
  final VoidCallback onSignOut;

  const ProfileActions({
    super.key,
    required this.isSaving,
    required this.onSaveChanges,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    if (isSaving) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
        ),
      );
    }

    return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  label: Text(
                    'Save Changes',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: onSaveChanges,
                  icon: const Icon(
                    Icons.save_rounded,
                    color: AppColors.secondary,
                    size: 16,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.secondary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.secondary,
                    size: 16,
                  ),
                  label: Text(
                    'Sign Out',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.secondary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        )
        .animate()
        .fade(delay: 200.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 350.ms,
        );
  }
}
