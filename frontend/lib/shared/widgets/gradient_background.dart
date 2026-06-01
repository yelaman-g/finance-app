import 'package:flutter/material.dart';

import '../../app/theme/app_gradients.dart';

/// Premium auth background: soft gradient + two decorative orbs.
class GradientBackground extends StatelessWidget {
  const GradientBackground({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppGradients.authBackground),
        ),
        Positioned(
          top: -120,
          right: -80,
          child: _Orb(size: MediaQuery.sizeOf(context).width * 0.9),
        ),
        Positioned(
          bottom: -160,
          left: -100,
          child: _Orb(size: MediaQuery.sizeOf(context).width * 1.0),
        ),
        child,
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppGradients.orb,
        ),
      ),
    );
  }
}
