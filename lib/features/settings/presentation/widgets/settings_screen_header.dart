import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/routes/navigation_manager.dart';

/// Shared header for settings sub-screens: a centered title with a
/// circular back button on the start edge. The back glyph auto-mirrors
/// under the ambient Directionality (matchTextDirection) — points right
/// in Arabic/RTL, left in English/LTR.
class SettingsScreenHeader extends StatelessWidget {
  final String title;
  const SettingsScreenHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        QeranSpacing.s16,
        QeranSpacing.s12,
        QeranSpacing.s16,
        QeranSpacing.s12,
      ),
      child: Row(
        children: [
          _BackButton(onTap: () => NavigationManager.pop(context)),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: QeranTypography.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Mirror the back button's footprint so the title stays centered.
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: QeranColors.paper,
      shape: const CircleBorder(
        side: BorderSide(color: QeranColors.wine08),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.chevron_left_rounded,
            color: QeranColors.wine,
            size: 18,
          ),
        ),
      ),
    );
  }
}
