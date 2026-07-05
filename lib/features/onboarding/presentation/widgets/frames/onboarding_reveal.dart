import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/motion/staggered_children.dart';
import 'package:qeran/core/design_system/tokens/qeran_motion.dart';

/// Staggered entrance for a vertical group of frame content — each child rises
/// (soft scale + fade) after the previous, so the frame *unfolds* on first
/// view. Honors reduced-motion: when the platform disables animations it
/// renders the column instantly.
class OnboardingReveal extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final Duration step;

  const OnboardingReveal({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.step = QeranMotion.staggerStep,
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: children,
      );
    }
    return StaggeredChildren(
      crossAxisAlignment: crossAxisAlignment,
      itemDuration: QeranMotion.gentle,
      step: step,
      children: children,
    );
  }
}
