import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
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
        AppDimens.p16,
        AppDimens.p16,
        AppDimens.p16,
        0,
      ),
      padding: const EdgeInsets.all(AppDimens.p12),
      decoration: BoxDecoration(
        color: v.background,
        borderRadius: BorderRadius.circular(AppDimens.r12),
        border: Border.all(color: v.foreground.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(v.icon, color: v.foreground, size: 20),
          const SizedBox(width: AppDimens.p12),
          Expanded(
            child: Text(
              v.localeKey.t(context),
              style: AppTextStyles.bodyMedium.copyWith(
                color: v.foreground,
                fontWeight: FontWeight.w700,
              ),
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
          background: Color(0xFFFFF8E1),
          foreground: Color(0xFFB18454),
          localeKey: LocaleKeys.profile_status_pending_review,
        );
      case ProfileStatus.hidden:
        return const _BannerVisual(
          icon: Icons.visibility_off_outlined,
          background: Color(0xFFEFEFEF),
          foreground: Color(0xFF6B6B6B),
          localeKey: LocaleKeys.profile_status_hidden,
        );
      case ProfileStatus.rejected:
        return const _BannerVisual(
          icon: Icons.error_outline_rounded,
          background: Color(0xFFFDECEC),
          foreground: Color(0xFFB12B41),
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
  final Color background;
  final Color foreground;
  final String localeKey;
  const _BannerVisual({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.localeKey,
  });
}
