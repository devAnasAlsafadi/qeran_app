import 'package:flutter/material.dart';
import 'package:qeran/features/profile/domain/entities/placement.dart';
import 'package:qeran/features/profile/domain/entities/placement_code.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';
import 'package:qeran/features/profile/presentation/widgets/placement/about_me_section.dart';
import 'package:qeran/features/profile/presentation/widgets/placement/inside_chips_section.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_chip.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/matchmaker_user_profile.dart';

/// The main نبذة card — the rounded-top "sheet" that overlaps the photo, like
/// the user-side full profile. Holds the matchmaker-only meta (status chip +
/// gender + email) at the top, then نبذة عني, then the physical/inside chips —
/// all in ONE card. The inside chips render WHITE ([QeranChipVariant.inside])
/// so they don't read as a beige smudge against the wine identity.
class MatchmakerProfileMainCard extends StatelessWidget {
  const MatchmakerProfileMainCard({super.key, required this.profile});

  final MatchmakerUserProfile profile;

  @override
  Widget build(BuildContext context) {
    final aboutMe = _find(PlacementCode.aboutMe);
    final inside = _find(PlacementCode.insideCard);
    final hasInside = inside != null && inside.items.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: QeranColors.paper,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(QeranRadii.panel),
        ),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(
        QeranSpacing.s20,
        QeranSpacing.s24,
        QeranSpacing.s20,
        QeranSpacing.s24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _MetaHeader(
            status: profile.profileStatus,
            gender: profile.gender,
            email: profile.email,
          ),
          if (aboutMe != null) ...[
            QeranSpacing.vs16,
            AboutMeSection(placement: aboutMe),
          ],
          if (hasInside) ...[
            QeranSpacing.vs16,
            InsideChipsSection(
              placement: inside,
              variant: QeranChipVariant.inside,
            ),
          ],
        ],
      ),
    );
  }

  Placement? _find(PlacementCode code) {
    for (final p in profile.placements) {
      if (p.code == code) return p;
    }
    return null;
  }
}

/// Top-of-card meta: a status chip + gender chip on one wrap, with the email on
/// its own row beneath (emails are long — a row reads cleaner than a chip).
class _MetaHeader extends StatelessWidget {
  const _MetaHeader({
    required this.status,
    required this.gender,
    required this.email,
  });

  final ProfileStatus status;
  final String gender;
  final String email;

  @override
  Widget build(BuildContext context) {
    final statusVisual = _statusVisualFor(status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: QeranSpacing.s8,
          runSpacing: QeranSpacing.s8,
          children: [
            if (statusVisual != null)
              QeranChip(
                label: statusVisual.labelKey.t(context),
                variant: QeranChipVariant.status,
                statusColor: statusVisual.color,
                icon: statusVisual.icon,
              ),
            if (gender.isNotEmpty)
              QeranChip(
                label: gender,
                variant: QeranChipVariant.meta,
                icon: Icons.person_outline_rounded,
              ),
          ],
        ),
        if (email.isNotEmpty) ...[
          QeranSpacing.vs12,
          Row(
            children: [
              const Icon(
                Icons.alternate_email_rounded,
                size: 18,
                color: QeranColors.wine,
              ),
              QeranSpacing.hs8,
              Expanded(
                child: Text(
                  email,
                  style: QeranTypography.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Status → (label, color, icon) for the chip. Mirrors the (now-removed)
  /// status banner's reviewer-facing copy. Visible / unknown → no chip.
  _StatusVisual? _statusVisualFor(ProfileStatus s) {
    switch (s) {
      case ProfileStatus.pendingReview:
        return const _StatusVisual(
          labelKey: LocaleKeys.matchmaker_profile_status_pending,
          color: QeranColors.wine,
          icon: Icons.hourglass_top_rounded,
        );
      case ProfileStatus.hidden:
        return const _StatusVisual(
          labelKey: LocaleKeys.matchmaker_profile_status_hidden,
          color: QeranColors.inkMuted,
          icon: Icons.visibility_off_outlined,
        );
      case ProfileStatus.rejected:
        return const _StatusVisual(
          labelKey: LocaleKeys.matchmaker_profile_status_rejected,
          color: QeranColors.danger,
          icon: Icons.error_outline_rounded,
        );
      case ProfileStatus.visible:
      case ProfileStatus.unknown:
        return null;
    }
  }
}

class _StatusVisual {
  const _StatusVisual({
    required this.labelKey,
    required this.color,
    required this.icon,
  });

  final String labelKey;
  final Color color;
  final IconData icon;
}
