import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Dark-wine gradient laid over the hero image so light text + chips stay
/// legible. Top is a faint wine tint, deepening toward the bottom.
class ProfileImageScrim extends StatelessWidget {
  const ProfileImageScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [QeranColors.wine20, QeranColors.wine80],
        ),
      ),
    );
  }
}

/// Centered gold lock + "photo available on mutual interest" line on a
/// dark-wine disc — shown while the hero photo is blurred.
class ProfilePrivacyLock extends StatelessWidget {
  const ProfilePrivacyLock({super.key});

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

/// Wine pill showing the compatibility score, light text + heart icon.
class ProfileMatchPill extends StatelessWidget {
  final String label;
  const ProfileMatchPill({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s12,
        vertical: QeranSpacing.s6,
      ),
      decoration: const BoxDecoration(
        color: QeranColors.wine,
        borderRadius: QeranRadii.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.favorite_rounded,
            size: 14,
            color: QeranColors.paper,
          ),
          const SizedBox(width: QeranSpacing.s6),
          Text(
            label,
            style: QeranTypography.label.copyWith(color: QeranColors.paper),
          ),
        ],
      ),
    );
  }
}

/// Translucent dark-wine pill with light text + a light hairline — the
/// nationality / profession / location chips overlaid on the image.
class ProfileOverlayChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  const ProfileOverlayChip({super.key, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s12,
        vertical: QeranSpacing.s6,
      ),
      decoration: BoxDecoration(
        color: QeranColors.overlayTintDark,
        borderRadius: QeranRadii.pill,
        border: Border.all(color: QeranColors.paper.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: QeranColors.paper),
            const SizedBox(width: QeranSpacing.s6),
          ],
          Text(
            label,
            style: QeranTypography.label.copyWith(color: QeranColors.paper),
          ),
        ],
      ),
    );
  }
}
