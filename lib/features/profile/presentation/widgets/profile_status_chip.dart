import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/profile_status.dart';

/// Compact on-brand chip echoing the owner's [ProfileStatus] on the
/// self-view. Verified reads gold, pending wine, rejected danger, hidden
/// muted; an unrecognised status renders nothing. Uses the DS status chip
/// (lives on the cream canvas above the hero, where its tint stays legible).
class ProfileStatusChip extends StatelessWidget {
  final ProfileStatus status;
  const ProfileStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(status);
    if (visual == null) return const SizedBox.shrink();
    return QeranChip(
      label: visual.localeKey.t(context),
      variant: QeranChipVariant.status,
      statusColor: visual.color,
      icon: visual.icon,
      compact: true,
    );
  }

  _StatusVisual? _visualFor(ProfileStatus s) {
    switch (s) {
      case ProfileStatus.visible:
        return const _StatusVisual(
          icon: Icons.verified_rounded,
          color: QeranColors.goldDeep,
          localeKey: LocaleKeys.profile_status_chip_verified,
        );
      case ProfileStatus.pendingReview:
        return const _StatusVisual(
          icon: Icons.hourglass_top_rounded,
          color: QeranColors.wine,
          localeKey: LocaleKeys.profile_status_chip_pending,
        );
      case ProfileStatus.hidden:
        return const _StatusVisual(
          icon: Icons.visibility_off_outlined,
          color: QeranColors.inkMuted,
          localeKey: LocaleKeys.profile_status_chip_hidden,
        );
      case ProfileStatus.rejected:
        return const _StatusVisual(
          icon: Icons.error_outline_rounded,
          color: QeranColors.danger,
          localeKey: LocaleKeys.profile_status_chip_rejected,
        );
      case ProfileStatus.unknown:
        return null;
    }
  }
}

class _StatusVisual {
  final IconData icon;
  final Color color;
  final String localeKey;
  const _StatusVisual({
    required this.icon,
    required this.color,
    required this.localeKey,
  });
}
