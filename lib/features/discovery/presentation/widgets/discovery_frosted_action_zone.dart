import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

/// The lightweight bottom zone of the discovery card. Wraps the action cluster
/// ([child]) in a translucent paper strip pinned at the card's bottom.
///
/// This intentionally avoids a live [BackdropFilter]; the border and paper
/// tint preserve separation while the card moves without re-blurring content.
class DiscoveryFrostedActionZone extends StatelessWidget {
  final Widget child;

  const DiscoveryFrostedActionZone({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: QeranColors.paper.withValues(alpha: 0.88),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: QeranSpacing.s16,
          vertical: QeranSpacing.s12,
        ),
        child: child,
      ),
    );
  }
}
