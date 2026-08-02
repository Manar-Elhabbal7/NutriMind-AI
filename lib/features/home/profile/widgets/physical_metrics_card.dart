import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class PhysicalMetricsCard extends StatelessWidget {
  final String gender;
  final ValueChanged<String> onGenderChanged;
  final TextEditingController heightController;
  final TextEditingController weightController;

  const PhysicalMetricsCard({
    super.key,
    required this.gender,
    required this.onGenderChanged,
    required this.heightController,
    required this.weightController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(
              alpha: isDark ? 0.01 : 0.04,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Physical Profile',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Divider(
            height: 8,
            color: isDark ? Colors.white12 : AppColors.divider,
          ),

          // Gender Selection Box
          Text(
            'Gender',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 12,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              // Female Option
              Expanded(
                child: GestureDetector(
                  onTap: () => onGenderChanged('Female'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: gender == 'Female'
                          ? AppColors.primaryExtraLight.withValues(
                              alpha: isDark ? 0.25 : 1.0,
                            )
                          : (isDark ? const Color(0xFF2C2C2C) : AppColors.fill),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: gender == 'Female'
                            ? AppColors.secondary.withValues(alpha: 0.5)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.female_rounded,
                          color: gender == 'Female'
                              ? AppColors.secondary
                              : (isDark ? Colors.white54 : AppColors.textSecondary),
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Female',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: gender == 'Female'
                                ? AppColors.secondary
                                : (isDark ? Colors.white54 : AppColors.textSecondary),
                            fontWeight: gender == 'Female'
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Male Option
              Expanded(
                child: GestureDetector(
                  onTap: () => onGenderChanged('Male'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: gender == 'Male'
                          ? AppColors.secondaryExtraLight.withValues(
                              alpha: isDark ? 0.25 : 1.0,
                            )
                          : (isDark ? const Color(0xFF2C2C2C) : AppColors.fill),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: gender == 'Male'
                            ? AppColors.secondary.withValues(alpha: 0.5)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.male_rounded,
                          color: gender == 'Male'
                              ? AppColors.secondary
                              : (isDark ? Colors.white54 : AppColors.textSecondary),
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Male',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: gender == 'Male'
                                ? AppColors.secondary
                                : (isDark ? Colors.white54 : AppColors.textSecondary),
                            fontWeight: gender == 'Male'
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Height & Weight Side-by-Side Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Height (Length) Field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Height',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: heightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: '165',
                        hintStyle: AppTextStyles.hintStyle.copyWith(
                          color: isDark
                              ? Colors.white30
                              : AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF2C2C2C) : AppColors.fill,
                        prefixIcon: Icon(
                          Icons.height_rounded,
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                          size: 20,
                        ),
                        suffixText: 'cm',
                        suffixStyle: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 10,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : AppColors.border,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.secondary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter height';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Weight Field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weight',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: '60',
                        hintStyle: AppTextStyles.hintStyle.copyWith(
                          color: isDark
                              ? Colors.white30
                              : AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF2C2C2C) : AppColors.fill,
                        prefixIcon: Icon(
                          Icons.scale_rounded,
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                          size: 20,
                        ),
                        suffixText: 'kg',
                        suffixStyle: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 10,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : AppColors.border,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.secondary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter weight';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fade(delay: 150.ms).slideY(begin: 0.08, end: 0, duration: 400.ms);
  }
}
