import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../generated/locale_keys.g.dart';

/// Standalone destructive logout card, kept on its own paper surface below the
/// settings list so the terminal action is segregated from the preference
/// rows. Shared by both roles (it superseded the two duplicated `_LogoutCard`s).
class SettingsLogoutCard extends StatelessWidget {
  const SettingsLogoutCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return QeranCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: QeranColors.danger12,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.logout_rounded,
              color: QeranColors.danger,
              size: 20,
            ),
          ),
          QeranSpacing.hs12,
          Expanded(
            child: Text(
              LocaleKeys.common_logout.t(context),
              style: QeranTypography.body.copyWith(color: QeranColors.danger),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: QeranColors.wine,
            size: 22,
          ),
        ],
      ),
    );
  }
}
