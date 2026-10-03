import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/utils/compact_count.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../domain/entities/community_comment.dart';

/// A comment's Like under its text: the heart, «إعجاب» / "Like", and the
/// count once there is one — gold-deep and filled when liked. The heart
/// lines up with the text above it; the tap area is the full 44 pt high. A
/// [dimmed] Like (read-only member, D9) still answers a tap, so the screen
/// can say why.
class CommentLikeButton extends StatelessWidget {
  const CommentLikeButton({
    super.key,
    required this.comment,
    this.dimmed = false,
    this.onTap,
  });

  final CommunityComment comment;
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final count = comment.likeCount;
    return Semantics(
      button: true,
      selected: comment.likedByMe,
      label: LocaleKeys.community_like.t(context),
      value: count > 0 ? '$count' : null,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: dimmed ? 0.4 : 1,
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: QeranSpacing.s8),
              child: _content(context),
            ),
          ),
        ),
      ),
    );
  }

  /// The heart, the word, and the count once there is one.
  Widget _content(BuildContext context) {
    final liked = comment.likedByMe;
    final color = liked ? QeranColors.goldDeep : QeranColors.inkBody;
    final count = comment.likeCount;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 18,
          color: color,
        ),
        QeranSpacing.hs4,
        Text(
          LocaleKeys.community_like.t(context),
          style: QeranTypography.label.copyWith(color: color),
        ),
        if (count > 0) ...[
          QeranSpacing.hs4,
          Text(
            formatCompactCount(count, context),
            style: QeranTypography.numeric.copyWith(
              fontSize: QeranTypography.label.fontSize,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}
