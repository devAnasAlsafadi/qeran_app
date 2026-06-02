import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Centered overlay on the blurred image (per Figma `home.png`):
/// a gold lock icon on a translucent dark-wine circular backdrop, with a
/// gold "photo available upon mutual interest" line beneath it. The
/// string is locale-driven.
class DiscoveryPrivacyMessage extends StatelessWidget {
  const DiscoveryPrivacyMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: QeranColors.overlayTintDark,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.lock_outline_rounded,
              color: QeranColors.gold,
              size: 22,
            ),
          ),
          const SizedBox(height: QeranSpacing.s12),
          Text(
            LocaleKeys.discovery_privacy_message.t(context),
            textAlign: TextAlign.center,
            style: QeranTypography.caption.copyWith(color: QeranColors.gold),
          ),
        ],
      ),
    );
  }
}
