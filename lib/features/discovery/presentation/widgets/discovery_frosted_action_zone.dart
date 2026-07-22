import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
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
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        // Very subtle hint of blur — minimal frost to lift the buttons slightly without washing out content.
        filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: QeranColors.paper.withValues(alpha: 0.35),
            border: Border.all(
              color: QeranColors.wine.withValues(alpha: 0.08),
              width: 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: QeranSpacing.s16,
              vertical: QeranSpacing.s12,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
