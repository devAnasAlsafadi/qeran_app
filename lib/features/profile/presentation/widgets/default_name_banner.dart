import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Prompt shown at the top of the settings tab while the member is still on
/// the server-assigned placeholder name. Dismissible, and the caller also
/// hides it once the name screen has been opened — see
/// [DefaultNameBannerSession] for why that flag is not persisted.
class DefaultNameBanner extends StatelessWidget {
  const DefaultNameBanner({
    super.key,
    required this.currentName,
    required this.onEdit,
    required this.onDismiss,
  });

  /// The placeholder itself, quoted back so the member recognises it. Comes
  /// from the profile payload — never hardcoded.
  final String currentName;
  final VoidCallback onEdit;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: QeranSpacing.s16),
      padding: const EdgeInsets.all(QeranSpacing.s16),
      decoration: BoxDecoration(
        color: QeranColors.gold12,
        borderRadius: QeranRadii.controlR,
        border: Border.all(color: QeranColors.gold40),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.badge_outlined,
                size: 18,
                color: QeranColors.goldDeep,
              ),
              QeranSpacing.hs8,
              Expanded(
                child: Text(
                  LocaleKeys.profile_name_default_banner
                      .t(context)
                      .replaceFirst('{name}', currentName),
                  style: QeranTypography.bodySm.copyWith(
                    color: QeranColors.inkBody,
                  ),
                  softWrap: true,
                ),
              ),
              // Compact target rather than a full row — the dismiss is the
              // secondary action here; the CTA below is the primary one.
              IconButton(
                onPressed: onDismiss,
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                tooltip: LocaleKeys.profile_name_default_banner_dismiss
                    .t(context),
                icon: const Icon(
                  Icons.close_rounded,
                  color: QeranColors.goldDeep,
                ),
              ),
            ],
          ),
          QeranSpacing.vs12,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: QeranButton(
              label: LocaleKeys.profile_name_default_banner_cta.t(context),
              variant: QeranButtonVariant.primaryWine,
              size: QeranButtonSize.sm,
              fullWidth: false,
              onPressed: onEdit,
            ),
          ),
        ],
      ),
    );
  }
}
