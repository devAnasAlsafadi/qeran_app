import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';

import '../../domain/entities/my_profile.dart';
import '../../domain/entities/profile_image.dart';
import 'placement/placement_renderer.dart';
import 'profile_header_gallery.dart';
import 'profile_status_banner.dart';

class MyProfileBody extends StatelessWidget {
  final MyProfile profile;
  const MyProfileBody({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ProfileStatusBanner(status: profile.profileStatus),
        const SizedBox(height: AppDimens.p16),
        ProfileHeaderGallery(
          images: _ownerImagesAsProfileImages(profile),
        ),
        const SizedBox(height: AppDimens.p16),
        _HeaderRow(profile: profile),
        const SizedBox(height: AppDimens.p16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p20),
          child: PlacementRenderer(placements: profile.placements),
        ),
        const SizedBox(height: AppDimens.p32),
      ],
    );
  }

  /// Widens [OwnerImage] to the sealed [ProfileImage] supertype expected
  /// by [ProfileHeaderGallery]. Order: primary first if any, then the
  /// rest in server order.
  List<ProfileImage> _ownerImagesAsProfileImages(MyProfile p) {
    final list = <ProfileImage>[];
    final primary = p.profileImage;
    if (primary != null) list.add(primary);
    for (final img in p.images) {
      if (primary != null && img.id == primary.id) continue;
      list.add(img);
    }
    return list;
  }
}

class _HeaderRow extends StatelessWidget {
  final MyProfile profile;
  const _HeaderRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.p20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.name,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${profile.gender} · ${profile.age}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if ((profile.email ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              profile.email!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
