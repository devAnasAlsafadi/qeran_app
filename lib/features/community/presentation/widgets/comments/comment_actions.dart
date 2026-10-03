import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../domain/entities/community_comment.dart';
import 'comment_like_button.dart';

/// Under a posted comment's text: Like, and «رد» / "Reply" when the
/// comment can be answered here ([onReply]) — never under a reply, nor for a
/// member who can't take part yet (C10).
class CommentActions extends StatelessWidget {
  const CommentActions({
    super.key,
    required this.comment,
    this.dimmed = false,
    this.onLike,
    this.onReply,
  });

  final CommunityComment comment;
  final bool dimmed;
  final VoidCallback? onLike;
  final VoidCallback? onReply;

  @override
  Widget build(BuildContext context) {
    final reply = onReply;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CommentLikeButton(comment: comment, dimmed: dimmed, onTap: onLike),
        if (reply != null) _Reply(onTap: reply),
      ],
    );
  }
}

class _Reply extends StatelessWidget {
  const _Reply({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = LocaleKeys.community_reply.t(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s8),
            child: _content(label),
          ),
        ),
      ),
    );
  }

  static Widget _content(String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.reply_rounded, size: 18, color: QeranColors.inkBody),
      QeranSpacing.hs4,
      Text(
        label,
        style: QeranTypography.label.copyWith(color: QeranColors.inkBody),
      ),
    ],
  );
}
