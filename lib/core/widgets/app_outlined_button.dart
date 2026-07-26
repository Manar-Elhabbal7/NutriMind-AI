import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color borderColor;
  final Color textColor;
  final double height;
  final double width;
  final double borderRadius;
  final TextStyle? textStyle;

  const AppOutlinedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.borderColor = AppColors.primary,
    this.textColor = AppColors.primary,
    this.height = 50,
    this.width = double.infinity,
    this.borderRadius = 10,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor, width: 1.5),
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Text(
          text,
          style:
              textStyle ??
              AppTextStyles.buttonTextStyle.copyWith(color: textColor),
        ),
      ),
    );
  }
}
