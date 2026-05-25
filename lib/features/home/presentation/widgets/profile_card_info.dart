import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/features/home/domain/entities/profile_entity.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'profile_tag_chip.dart';

/// The white "نبذة عني" section that sits underneath the photo inside the
/// card. Renders the bio paragraph and the religion/height/weight chips.
class ProfileCardInfo extends StatelessWidget {
  final ProfileEntity profile;

  const ProfileCardInfo({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final chips = _chipsFor(profile);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.p16,
        AppDimens.p16,
        AppDimens.p16,
        AppDimens.p20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LocaleKeys.home_about_me.t(context),
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppDimens.p8),
          if (profile.bio != null && profile.bio!.isNotEmpty)
            Text(
              profile.bio!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: AppDimens.p12),
            Wrap(
              spacing: AppDimens.p8,
              runSpacing: AppDimens.p8,
              children: chips,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _chipsFor(ProfileEntity p) {
    final out = <Widget>[];
    if (p.religion != null && p.religion!.isNotEmpty) {
      out.add(ProfileTagChip(label: p.religion!));
    }
    if (p.heightCm != null) {
      out.add(
        ProfileTagChip(
          label: LocaleKeys.home_height_chip.tr(
            namedArgs: {'value': '${p.heightCm}'},
          ),
        ),
      );
    }
    if (p.weightKg != null) {
      out.add(
        ProfileTagChip(
          label: LocaleKeys.home_weight_chip.tr(
            namedArgs: {'value': '${p.weightKg}'},
          ),
        ),
      );
    }
    return out;
  }
}
