import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

/// One labelled field on the profile-edit form — the question text (with a
/// required marker) above its input. [child] is the type-specific input
/// (wired in the next sub-step); for now callers pass a read-only summary.
class ProfileEditField extends StatelessWidget {
  final String label;
  final bool isRequired;
  final bool isInvalid;
  final Widget child;

  const ProfileEditField({
    super.key,
    required this.label,
    required this.isRequired,
    required this.child,
    this.isInvalid = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = isInvalid ? QeranColors.danger : QeranColors.wine;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: QeranSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: QeranTypography.subtitle.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isRequired)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: QeranSpacing.s4,
                  ),
                  child: Text(
                    '*',
                    style: QeranTypography.subtitle.copyWith(
                      color: QeranColors.danger,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: QeranSpacing.s8),
          child,
        ],
      ),
    );
  }
}
