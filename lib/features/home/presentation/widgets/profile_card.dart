import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/features/home/domain/entities/profile_entity.dart';
import 'profile_card_info.dart';
import 'profile_card_photo.dart';

/// The main matchmaking card on the Home screen.
///
/// Layout:
///   • Photo section (Expanded) — fills the remaining vertical space.
///   • Info section (shrink-wrap) — bio + chips, sized to its content.
///
/// Sub-pieces live in [ProfileCardPhoto] and [ProfileCardInfo] so each
/// file stays well under the 200-line cap.
class ProfileCard extends StatelessWidget {
  final ProfileEntity profile;

  const ProfileCard({super.key, required this.profile});

  static const double _radius = AppDimens.r16 + 8; // 24

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: ProfileCardPhoto(profile: profile)),
            ProfileCardInfo(profile: profile),
          ],
        ),
      ),
    );
  }
}
