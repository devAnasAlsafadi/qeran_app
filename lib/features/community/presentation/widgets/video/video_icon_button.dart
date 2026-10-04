import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/extensions/localization_extension.dart';

/// A 44 pt control on a video, its icon in paper; [label] is a locale key
/// for screen readers.
class VideoIconButton extends StatelessWidget {
  const VideoIconButton({
    super.key,
    required this.icon,
    required this.size,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label.t(context),
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: SizedBox.square(
          dimension: 44,
          child: Icon(icon, size: size, color: QeranColors.paper),
        ),
      ),
    );
  }
}
