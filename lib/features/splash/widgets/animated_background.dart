import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * 2 * math.pi;

        return Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.3),
                  radius: 1.2,
                  colors: [
                    Color(0xFFEDE8FA),
                    Color(0xFFE6E0F8),
                    Color(0xFFD8CFF0),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
            _AmbientOrb(
              alignment: Alignment(
                -0.85 + math.sin(t) * 0.04,
                -0.55 + math.cos(t * 0.7) * 0.03,
              ),
              size: 90,
              color: const Color(0xFF81C784).withValues(alpha: 0.18),
            ),
            _AmbientOrb(
              alignment: Alignment(
                0.9 + math.cos(t * 0.8) * 0.04,
                -0.35 + math.sin(t * 0.6) * 0.03,
              ),
              size: 70,
              color: const Color(0xFFB39DDB).withValues(alpha: 0.16),
            ),
            _AmbientOrb(
              alignment: Alignment(
                -0.5 + math.sin(t * 0.5) * 0.05,
                0.75 + math.cos(t * 0.4) * 0.03,
              ),
              size: 55,
              color: const Color(0xFF43A047).withValues(alpha: 0.12),
            ),
            _AmbientOrb(
              alignment: Alignment(
                0.65 + math.cos(t * 0.6) * 0.04,
                0.85 + math.sin(t * 0.5) * 0.03,
              ),
              size: 45,
              color: const Color(0xFF9575CD).withValues(alpha: 0.14),
            ),
          ],
        );
      },
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({
    required this.alignment,
    required this.size,
    required this.color,
  });

  final Alignment alignment;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size * 0.6,
              spreadRadius: size * 0.15,
            ),
          ],
        ),
      ),
    );
  }
}
