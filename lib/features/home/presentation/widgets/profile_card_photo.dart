import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/features/home/domain/entities/profile_entity.dart';

/// The top portion of the profile card: photo + dark gradient + the
/// name/age/city/job overlay + the small privacy-eye badge.
class ProfileCardPhoto extends StatelessWidget {
  final ProfileEntity profile;

  const ProfileCardPhoto({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _PhotoOrPlaceholder(url: profile.photoUrl),
        const _BottomGradient(),
        const Positioned(
          top: AppDimens.p12,
          right: AppDimens.p12,
          child: _PrivacyBadge(),
        ),
        Positioned(
          left: AppDimens.p16,
          right: AppDimens.p16,
          bottom: AppDimens.p16,
          child: _OverlayInfo(profile: profile),
        ),
      ],
    );
  }
}

class _PhotoOrPlaceholder extends StatelessWidget {
  final String? url;
  const _PhotoOrPlaceholder({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const DecoratedBox(
        decoration: BoxDecoration(color: AppColors.darkSurface),
        child: Center(
          child: Icon(
            Icons.person,
            size: 96,
            color: AppColors.textMuted,
          ),
        ),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _PhotoOrPlaceholder(url: null),
    );
  }
}

class _BottomGradient extends StatelessWidget {
  const _BottomGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.45, 1.0],
          colors: [Colors.transparent, Color(0xCC000000)],
        ),
      ),
    );
  }
}

class _PrivacyBadge extends StatelessWidget {
  const _PrivacyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.p8),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.visibility_off_outlined,
        size: 18,
        color: AppColors.white,
      ),
    );
  }
}

class _OverlayInfo extends StatelessWidget {
  final ProfileEntity profile;
  const _OverlayInfo({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${profile.name} ${profile.age}',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: AppDimens.p4),
        _IconLine(
          icon: Icons.location_on_outlined,
          text: '${profile.city}، ${profile.country}',
        ),
        if (profile.occupation != null && profile.occupation!.isNotEmpty) ...[
          const SizedBox(height: AppDimens.p4),
          _IconLine(
            icon: Icons.work_outline,
            text: profile.occupation!,
          ),
        ],
      ],
    );
  }
}

class _IconLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppDimens.p4),
        Icon(icon, size: 14, color: AppColors.white),
      ],
    );
  }
}
