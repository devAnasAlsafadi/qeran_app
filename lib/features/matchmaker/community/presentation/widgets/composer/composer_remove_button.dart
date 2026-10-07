import 'package:flutter/material.dart';

import '../../../../../../core/design_system/tokens/qeran_colors.dart';

/// × on her media in the composer (C5, C6): a dark disc in a 48 pt target,
/// named for screen readers by [label].
class ComposerRemoveButton extends StatelessWidget {
  const ComposerRemoveButton({
    super.key,
    required this.label,
    required this.onTap,
    this.disc = 26,
  });

  final String label;
  final VoidCallback onTap;

  /// The disc's side: 26 on a thumbnail, 30 on the video (as drawn).
  final double disc;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: Container(
              width: disc,
              height: disc,
              decoration: const BoxDecoration(
                color: QeranColors.overlayTintDark,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: disc * 0.6,
                color: QeranColors.paper,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
