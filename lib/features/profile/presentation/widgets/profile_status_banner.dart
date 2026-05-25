import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/profile_status.dart';

/// Banner rendered at the top of [MyProfileScreen] when the user's
/// profile is in a non-Visible state. Returns `SizedBox.shrink()` for
/// visible/unknown so the screen layout stays clean.
class ProfileStatusBanner extends StatelessWidget {
  final ProfileStatus status;
  const ProfileStatusBanner({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final v = _visualFor(status);
    if (v == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s16,
        QeranSpacing.s20,
        0,
      ),
      padding: const EdgeInsets.all(QeranSpacing.s12),
      decoration: BoxDecoration(
        color: v.foreground.withValues(alpha: 0.10),
        borderRadius: QeranRadii.controlR,
        border: Border.all(color: v.foreground.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(v.icon, color: v.foreground, size: 20),
          QeranSpacing.hs12,
          Expanded(
            child: Text(
              v.localeKey.t(context),
              style: QeranTypography.label.copyWith(color: v.foreground),
            ),
          ),
        ],
      ),
    );
  }

  _BannerVisual? _visualFor(ProfileStatus s) {
    switch (s) {
      case ProfileStatus.pendingReview:
        return const _BannerVisual(
          icon: Icons.hourglass_top_rounded,
          foreground: QeranColors.wine,
          localeKey: LocaleKeys.profile_status_pending_review,
        );
      case ProfileStatus.hidden:
        return const _BannerVisual(
          icon: Icons.visibility_off_outlined,
          foreground: QeranColors.inkMuted,
          localeKey: LocaleKeys.profile_status_hidden,
        );
      case ProfileStatus.rejected:
        return const _BannerVisual(
          icon: Icons.error_outline_rounded,
          foreground: QeranColors.danger,
          localeKey: LocaleKeys.profile_status_rejected,
        );
      case ProfileStatus.visible:
      case ProfileStatus.unknown:
        return null;
    }
  }
}

class _BannerVisual {
  final IconData icon;
  final Color foreground;
  final String localeKey;
  const _BannerVisual({
    required this.icon,
    required this.foreground,
    required this.localeKey,
  });
}
