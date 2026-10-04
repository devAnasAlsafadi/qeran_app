import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../blocs/comments/comment_thread.dart';
import '../community_page_error.dart';
import 'comment_row.dart';

/// Under a comment and its replies (C2): «عرض الردود» before any are shown,
/// «عرض ردود أخرى» while the server has more — or under a landing's reply
/// (C8) — counted in their plural forms (Q5), a loader while a page comes,
/// or the page error with its retry. Nothing once every reply is shown.
class RepliesLink extends StatelessWidget {
  const RepliesLink({super.key, required this.thread, required this.onShow});

  final CommentThread thread;
  final VoidCallback onShow;

  static const double height = 44;

  @override
  Widget build(BuildContext context) {
    return switch (thread.repliesStatus) {
      RepliesStatus.loading => const SizedBox(
        height: height,
        child: Padding(
          padding: EdgeInsetsDirectional.only(start: CommentRow.replyIndent),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: QeranLoader(size: 20),
          ),
        ),
      ),
      RepliesStatus.failed => CommunityPageError(
        onRetry: onShow,
        padding: const EdgeInsetsDirectional.only(
          start: CommentRow.replyIndent,
          end: QeranSpacing.s16,
        ),
        alignment: MainAxisAlignment.start,
      ),
      _ when thread.offersReplies => _Link(
        text: _label(context),
        onTap: onShow,
      ),
      _ => const SizedBox.shrink(),
    };
  }

  String _label(BuildContext context) =>
      (thread.repliesPage == 0 && thread.landed.isEmpty
              ? LocaleKeys.community_view_replies
              : LocaleKeys.community_more_replies)
          .tPlural(context, thread.hiddenReplies);
}

class _Link extends StatelessWidget {
  const _Link({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  /// The short hairline before the words.
  static const _line = SizedBox(
    width: 22,
    height: 1,
    child: ColoredBox(color: QeranColors.hairline),
  );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: RepliesLink.height,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: CommentRow.replyIndent,
            end: QeranSpacing.s16,
          ),
          child: Row(
            children: [
              _line,
              QeranSpacing.hs8,
              Flexible(
                child: Text(
                  text,
                  style: QeranTypography.label.copyWith(
                    color: QeranColors.wine,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
