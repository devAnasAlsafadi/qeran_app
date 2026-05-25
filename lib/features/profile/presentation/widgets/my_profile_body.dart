import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';

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
        QeranSpacing.vs20,
        ProfileHeaderGallery(
          images: _ownerImagesAsProfileImages(profile),
        ),
        QeranSpacing.vs20,
        _HeaderRow(profile: profile),
        QeranSpacing.vs20,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s20),
          child: PlacementRenderer(placements: profile.placements),
        ),
        QeranSpacing.vs32,
      ],
    );
  }

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
    final email = (profile.email ?? '').trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(profile.name, style: QeranTypography.headline),
          QeranSpacing.vs12,
          Wrap(
            spacing: QeranSpacing.s8,
            runSpacing: QeranSpacing.s8,
            children: [
              QeranChip(
                label: profile.gender,
                variant: QeranChipVariant.meta,
                icon: Icons.person_outline_rounded,
              ),
              QeranChip(
                label: '${profile.age}',
                variant: QeranChipVariant.meta,
                icon: Icons.cake_outlined,
              ),
              if (email.isNotEmpty)
                QeranChip(
                  label: email,
                  variant: QeranChipVariant.meta,
                  icon: Icons.mail_outline_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
