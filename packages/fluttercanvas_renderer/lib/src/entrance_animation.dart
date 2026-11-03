import 'package:flutter/material.dart';

/// The ways a widget can appear when its screen opens.
enum EntranceEffect { fade, slideUp, slideLeft, scale }

/// Plays a short entrance animation once, when the widget first appears.
class EntranceAnimation extends StatelessWidget {
  const EntranceAnimation({
    super.key,
    required this.effect,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
  });

  final EntranceEffect effect;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) {
        final faded = Opacity(opacity: value, child: child);
        return switch (effect) {
          EntranceEffect.fade => faded,
          EntranceEffect.slideUp => Transform.translate(
              offset: Offset(0, 24 * (1 - value)),
              child: faded,
            ),
          EntranceEffect.slideLeft => Transform.translate(
              offset: Offset(24 * (1 - value), 0),
              child: faded,
            ),
          EntranceEffect.scale => Transform.scale(
              scale: 0.85 + 0.15 * value,
              child: faded,
            ),
        };
      },
    );
  }
}
