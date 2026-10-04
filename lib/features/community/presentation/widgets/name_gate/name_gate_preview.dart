import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../domain/entities/community_author.dart';
import '../comments/comment_row.dart';
import '../community_author_avatar.dart';
import '../community_author_name.dart';

/// How the member will show in Community (F1–F3): a comment row's own
/// picture, name and time over a stand-in for their words — the row's
/// pieces, so the preview can't drift from the real thing.
class NameGatePreview extends StatelessWidget {
  const NameGatePreview({super.key, required this.name});

  final String name;

  static const _padding = EdgeInsets.symmetric(
    horizontal: QeranSpacing.s16,
    vertical: QeranSpacing.s12,
  );

  /// The member as a comment would name them.
  CommunityAuthor get _author =>
      CommunityAuthor(id: '', displayName: name, isMatchmaker: false);

  @override
  Widget build(BuildContext context) {
    final author = _author;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          LocaleKeys.community_name_gate_preview.t(context),
          style: QeranTypography.caption,
        ),
        QeranSpacing.vs8,
        QeranCard(
          padding: _padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommunityAuthorAvatar(
                author: author,
                size: CommentRow.avatarSize,
              ),
              QeranSpacing.hs12,
              Expanded(child: _Lines(author)),
            ],
          ),
        ),
      ],
    );
  }
}

/// The name and «· الآن», then where the comment would be.
class _Lines extends StatelessWidget {
  const _Lines(this.author);

  final CommunityAuthor author;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CommunityAuthorName(
          author: author,
          style: QeranTypography.label,
          trailing: Text(
            '· ${LocaleKeys.time_just_now.t(context)}',
            style: QeranTypography.caption,
          ),
        ),
        const SizedBox(height: QeranSpacing.s2),
        Text(
          LocaleKeys.community_name_gate_preview_text.t(context),
          style: QeranTypography.bodySm.copyWith(color: QeranColors.inkMuted),
        ),
      ],
    );
  }
}
