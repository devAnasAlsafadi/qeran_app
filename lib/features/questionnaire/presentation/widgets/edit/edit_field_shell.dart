import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

/// The closed, tappable field row used by the edit form's dropdown and drum
/// fields — a soft cream-surface box showing the current value (or a muted
/// placeholder) with a trailing chevron. Matches the Figma closed-dropdown
/// shape, painted in our identity (no greys).
class EditFieldShell extends StatelessWidget {
  final String value;
  final String placeholder;
  final VoidCallback onTap;

  const EditFieldShell({
    super.key,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;
    return Material(
      color: QeranColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: QeranRadii.controlR,
        side: BorderSide(color: QeranColors.hairline),
      ),
      child: InkWell(
        borderRadius: QeranRadii.controlR,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            QeranSpacing.s16,
            QeranSpacing.s12,
            QeranSpacing.s12,
            QeranSpacing.s12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? value : placeholder,
                  overflow: TextOverflow.ellipsis,
                  style: QeranTypography.body.copyWith(
                    color: hasValue ? QeranColors.inkStrong : QeranColors.inkMuted,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: QeranColors.wine,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
