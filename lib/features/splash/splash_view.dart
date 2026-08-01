import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../auth/screens/login_screen.dart';
import 'widgets/animated_background.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  Timer? _navigateTimer;

  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    _navigateTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _navigateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.surface],
          ),
        ),
        child: Stack(
          children: [
            const AnimatedBackground(),

            // Purple Glow
            Positioned(
              top: 90,
              left: 50,
              right: 50,
              child: Container(
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withValues(alpha: 0.28),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 24,
                      ),
                      child: Center(
                        child:
                            Image.asset(
                                  'assets/images/healthy_food.png',
                                  fit: BoxFit.contain,
                                )
                                .animate(
                                  onPlay: (controller) =>
                                      controller.repeat(reverse: true),
                                )
                                .fade(duration: 900.ms)
                                .scale(
                                  begin: const Offset(.92, .92),
                                  end: const Offset(1, 1),
                                  duration: 900.ms,
                                  curve: Curves.easeOut,
                                )
                                .moveY(
                                  begin: -8,
                                  end: 8,
                                  duration: 2500.ms,
                                  curve: Curves.easeInOut,
                                ),
                      ),
                    ),
                  ),

                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _AppTitle()
                            .animate()
                            .fade(delay: 300.ms)
                            .slideY(begin: .25, end: 0, duration: 700.ms),

                        const SizedBox(height: 12),

                        Text(
                              "Your AI Nutrition Assistant",
                              style: AppTextStyles.bodyRegular.copyWith(
                                fontSize: 17,
                                color: const Color(0xff6F6F86),
                                fontWeight: FontWeight.w500,
                                letterSpacing: .3,
                              ),
                            )
                            .animate()
                            .fade(delay: 500.ms)
                            .slideY(begin: .2, end: 0, duration: 700.ms),
                      ],
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(bottom: size.height * .05),
                    child: const _LoadingDots(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      fontSize: 38,
      fontWeight: FontWeight.w700,
      letterSpacing: -.5,
      height: 1,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'NutriMind',
          style: AppTextStyles.poppins.merge(
            titleStyle.copyWith(color: const Color(0xFF222222)),
          ),
        ),

        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF43C878), Color(0xFF8B5CF6)],
            ).createShader(bounds);
          },
          child: Text(
            ' AI',
            style: AppTextStyles.poppins.merge(
              titleStyle.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots();

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.primary, AppColors.secondary, AppColors.primary];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) =>
            Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: colors[index],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors[index].withValues(alpha: 0.25),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                )
                .animate(
                  delay: Duration(milliseconds: index * 220),
                  onPlay: (controller) => controller.repeat(),
                )
                .scaleXY(
                  begin: .8,
                  end: 1.25,
                  duration: 600.ms,
                  curve: Curves.easeInOut,
                )
                .then()
                .scaleXY(
                  begin: 1.25,
                  end: .8,
                  duration: 600.ms,
                  curve: Curves.easeInOut,
                ),
      ),
    );
  }
}
