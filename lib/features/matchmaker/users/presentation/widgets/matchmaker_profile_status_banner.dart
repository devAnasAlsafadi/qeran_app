import 'package:flutter/material.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';

/// Matchmaker-perspective status banner. Mirrors the user-side
/// `ProfileStatusBanner` visual (icon + tinted pill) but the copy is
/// written for the reviewer ("awaiting your review") rather than the
/// profile owner ("your profile is …"), since the user-side strings would
/// read wrong here. Visible/unknown render nothing.
class MatchmakerProfileStatusBanner extends StatelessWidget {
  const MatchmakerProfileStatusBanner({super.key, required this.status});

  final ProfileStatus status;

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
          localeKey: LocaleKeys.matchmaker_profile_status_pending,
        );
      case ProfileStatus.hidden:
        return const _BannerVisual(
          icon: Icons.visibility_off_outlined,
          foreground: QeranColors.inkMuted,
          localeKey: LocaleKeys.matchmaker_profile_status_hidden,
        );
      case ProfileStatus.rejected:
        return const _BannerVisual(
          icon: Icons.error_outline_rounded,
          foreground: QeranColors.danger,
          localeKey: LocaleKeys.matchmaker_profile_status_rejected,
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
