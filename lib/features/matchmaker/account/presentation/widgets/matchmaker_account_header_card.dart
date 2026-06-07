import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_user_avatar.dart';
import '../../domain/entities/matchmaker_me.dart';

/// Profile header for the account screen — gold-ringed avatar + name + email +
/// a "تعديل الملف" link (drives the same edit-name action as the row). The
/// avatar uses the JWT-headered [MatchmakerUserAvatar].
class MatchmakerAccountHeaderCard extends StatelessWidget {
  const MatchmakerAccountHeaderCard({
    super.key,
    required this.me,
    required this.onEdit,
  });

  final MatchmakerMe me;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return QeranCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: QeranColors.gold, width: 1.5),
            ),
            padding: const EdgeInsets.all(2),
            child: MatchmakerUserAvatar(url: me.image?.url, size: 58),
          ),
          QeranSpacing.hs16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  me.name,
                  style: QeranTypography.headline
                      .copyWith(color: QeranColors.wine),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                QeranSpacing.vs4,
                Text(
                  me.email,
                  style: QeranTypography.bodySm
                      .copyWith(color: QeranColors.inkBody),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                QeranSpacing.vs8,
                _EditLink(onTap: onEdit),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditLink extends StatelessWidget {
  const _EditLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: QeranRadii.xsR,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_outlined, size: 14, color: QeranColors.gold),
            QeranSpacing.hs4,
            Text(
              LocaleKeys.matchmaker_account_edit_profile.t(context),
              style: QeranTypography.caption.copyWith(
                color: QeranColors.wine,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
