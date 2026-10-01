import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Centered overlay on the blurred image: a gold lock on a wine disc, and the
/// gold "photo available upon mutual interest" line on a wine backing beneath
/// it. The string is locale-driven.
///
/// This is the privacy message, and the photo behind it can be any colour, so
/// both backings are [QeranColors.wine80]. Over pure white — the worst case,
/// before the photo's own wine tint is counted — gold on wine80 measures
/// 4.52:1, clear of WCAG AA's 4.5:1 for small text; on the lighter overlay
/// tint it was 2.06:1.
///
/// The caption's backing rounds at [QeranRadii.controlR], not a full stadium:
/// on one line the two look the same, but once a large text size wraps the
/// caption, a stadium's curve would cut into the corner letters.
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
              color: QeranColors.wine80,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.lock_outline_rounded,
              color: QeranColors.gold,
              size: 22,
            ),
          ),
          const SizedBox(height: QeranSpacing.s12),
          DecoratedBox(
            decoration: const ShapeDecoration(
              color: QeranColors.wine80,
              shape: RoundedRectangleBorder(
                borderRadius: QeranRadii.controlR,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: QeranSpacing.s12,
                vertical: QeranSpacing.s4,
              ),
              child: Text(
                LocaleKeys.discovery_privacy_message.t(context),
                textAlign: TextAlign.center,
                style: QeranTypography.caption.copyWith(
                  color: QeranColors.gold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
