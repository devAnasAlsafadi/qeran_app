import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/utils/compact_count.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../domain/entities/community_post.dart';

/// A post card's bottom row: Like, and the discussion (A15–A17, A20). Counts
/// in thousands read «1.2 ألف» / "1.2K". In the feed the discussion half
/// opens the post (S1) — «ابدأ النقاش ›» / "Discuss ›" while it has no
/// comments; on the post screen ([interactive] false) it is a quiet label.
/// A read-only member's Like is dimmed but still answers a tap, so the feed
/// can say why (D9).
class PostCardFooter extends StatelessWidget {
  const PostCardFooter({
    super.key,
    required this.post,
    required this.interactive,
    this.likeDimmed = false,
    this.onLike,
    this.onDiscussion,
  });

  final CommunityPost post;

  /// True in the feed: the discussion half is a way into the post.
  final bool interactive;
  final bool likeDimmed;
  final VoidCallback? onLike;
  final VoidCallback? onDiscussion;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: QeranColors.divider)),
      ),
      child: SizedBox(
        height: 48,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _like(context)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: QeranSpacing.s12),
              child: SizedBox(
                width: 1,
                child: ColoredBox(color: QeranColors.divider),
              ),
            ),
            Expanded(child: _discussion(context)),
          ],
        ),
      ),
    );
  }

  Widget _like(BuildContext context) {
    final liked = post.likedByMe;
    final color = liked ? QeranColors.goldDeep : QeranColors.inkBody;
    final count = post.likeCount;
    final label = LocaleKeys.community_like.t(context);
    return Semantics(
      button: true,
      selected: liked,
      label: label,
      value: count > 0 ? '$count' : null,
      excludeSemantics: true,
      child: InkWell(
        onTap: onLike,
        child: Opacity(
          opacity: likeDimmed ? 0.4 : 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 22,
                color: color,
              ),
              const SizedBox(width: QeranSpacing.s6),
              count > 0
                  ? Text(
                      formatCompactCount(count, context),
                      style: _count(color),
                    )
                  : Text(
                      label,
                      style: QeranTypography.label.copyWith(color: color),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _discussion(BuildContext context) {
    final color = interactive ? QeranColors.wine : QeranColors.inkMuted;
    final count = post.commentCount;
    final label =
        (interactive && count == 0
                ? LocaleKeys.community_discussion_start
                : LocaleKeys.community_discussion)
            .t(context);
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 20, color: color),
          QeranSpacing.hs4,
          Flexible(
            child: Text(
              label,
              style: QeranTypography.label.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (count > 0) ...[
            QeranSpacing.hs4,
            Text('·', style: QeranTypography.label.copyWith(color: color)),
            QeranSpacing.hs4,
            Text(formatCompactCount(count, context), style: _count(color)),
          ],
          if (interactive)
            Icon(Icons.chevron_right_rounded, size: 18, color: color),
        ],
      ),
    );
    return Semantics(
      button: interactive,
      label: label,
      value: count > 0 ? '$count' : null,
      excludeSemantics: true,
      child: interactive ? InkWell(onTap: onDiscussion, child: row) : row,
    );
  }

  /// Counts in the numeric face (Montserrat, tabular figures) at label size.
  static TextStyle _count(Color color) => QeranTypography.numeric.copyWith(
    fontSize: QeranTypography.label.fontSize,
    color: color,
  );
}
