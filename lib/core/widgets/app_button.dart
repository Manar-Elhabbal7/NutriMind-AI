import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final double height;
  final double width;
  final double borderRadius;
  final double elevation;
  final TextStyle? textStyle;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = AppColors.white,
    this.height = 50,
    this.width = double.infinity,
    this.borderRadius = 10,
    this.elevation = 2,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Text(
          text,
          style:
              textStyle ??
              AppTextStyles.buttonTextStyle.copyWith(color: foregroundColor),
        ),
      ),
    );
  }
}
