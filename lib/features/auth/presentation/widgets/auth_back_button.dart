import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';

/// Shared back button used across auth screens that have a back navigation
/// action. The icon auto-mirrors under the ambient Directionality
/// (matchTextDirection): points right in Arabic/RTL, left in English/LTR.
class AuthBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  /// Chevron colour. Defaults to wine for the light auth surfaces; the
  /// wine hero passes gold so the control reads on the dark band.
  final Color color;

  const AuthBackButton({
    super.key,
    required this.onPressed,
    this.color = QeranColors.wine,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          Icons.chevron_left_rounded,
          color: color,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
