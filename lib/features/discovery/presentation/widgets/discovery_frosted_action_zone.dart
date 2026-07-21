import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

/// The frosted bottom zone of the discovery card. Wraps the action cluster
/// ([child]) in a blur + soft wine scrim strip pinned at the card's bottom.
///
/// The [BackdropFilter] is scoped to THIS strip only (perf) so card content
/// scrolling BEHIND the buttons reads blurred, and becomes clear the moment
/// it scrolls above them. The wine gradient sits behind the buttons for
/// contrast; the rounded bottom corners match the card so the strip reads as
/// part of it.
class DiscoveryFrostedActionZone extends StatelessWidget {
  final Widget child;

  const DiscoveryFrostedActionZone({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(QeranRadii.panel),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                QeranColors.wine.withValues(alpha: 0.0),
                QeranColors.wine.withValues(alpha: 0.32),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              QeranSpacing.s16,
              QeranSpacing.s20,
              QeranSpacing.s16,
              QeranSpacing.s16,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
