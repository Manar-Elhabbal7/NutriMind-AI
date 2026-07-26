import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.showBackButton = false,
  });

  final Widget child;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            if (showBackButton)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.85),
                      foregroundColor: AppColors.textPrimary,
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
