import 'package:flutter/material.dart';
import 'package:qeran/features/community/domain/entities/community_viewer.dart';
import 'package:qeran/features/community/presentation/screens/community_me.dart';
import 'package:qeran/features/community/presentation/widgets/community_author_avatar.dart';
import 'package:qeran/features/community/presentation/widgets/community_author_name.dart';

import '../../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../generated/locale_keys.g.dart';

/// Who the post will be from, and who sees it (C1): her picture, her name in
/// its own direction (B2) with «خطّابة», and «يظهر لكل الأعضاء والخطّابات».
class ComposerAuthorLine extends StatelessWidget {
  const ComposerAuthorLine({super.key});

  @override
  Widget build(BuildContext context) {
    final me = communityMe(context, CommunityViewer.matchmaker);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s16,
        QeranSpacing.s20,
        QeranSpacing.s6,
      ),
      child: Row(
        children: [
          CommunityAuthorAvatar(author: me),
          QeranSpacing.hs12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommunityAuthorName(author: me),
                const SizedBox(height: QeranSpacing.s2),
                _audience(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _audience(BuildContext context) => Row(
    children: [
      const Icon(Icons.public_rounded, size: 14, color: QeranColors.inkMuted),
      const SizedBox(width: QeranSpacing.s4),
      Flexible(
        child: Text(
          LocaleKeys.matchmaker_community_audience.t(context),
          style: QeranTypography.caption,
        ),
      ),
    ],
  );
}
