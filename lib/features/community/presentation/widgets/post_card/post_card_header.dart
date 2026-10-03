import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/utils/relative_time.dart';
import '../../../domain/entities/community_post.dart';
import '../community_author_avatar.dart';
import '../community_author_name.dart';

/// A post card's top row: the author's picture, name and chip, how long ago
/// it was posted (long form, Q6; left out when the server sent no time), and
/// the post's ⋮ menu when there is one.
class PostCardHeader extends StatelessWidget {
  const PostCardHeader({super.key, required this.post, this.menu});

  final CommunityPost post;

  /// The ⋮ button, built from what this viewer may do with the post.
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    final time = QeranRelativeTime.ago(post.createdAt, context);
    return Padding(
      // The ⋮ button brings its own 44 pt tap area to the end edge.
      padding: EdgeInsetsDirectional.only(
        start: QeranSpacing.s16,
        end: menu == null ? QeranSpacing.s16 : QeranSpacing.s2,
        top: QeranSpacing.s12,
        bottom: QeranSpacing.s8,
      ),
      child: Row(
        children: [
          CommunityAuthorAvatar(author: post.author),
          QeranSpacing.hs12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CommunityAuthorName(author: post.author),
                if (time != null) ...[
                  const SizedBox(height: QeranSpacing.s2),
                  Text(time, style: QeranTypography.caption),
                ],
              ],
            ),
          ),
          ?menu,
        ],
      ),
    );
  }
}
