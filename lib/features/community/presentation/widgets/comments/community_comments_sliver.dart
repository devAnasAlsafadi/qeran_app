import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../domain/entities/community_comment.dart';
import '../../blocs/comments/comment_thread.dart';
import '../../blocs/comments/community_comments_cubit.dart';
import '../../blocs/comments/community_comments_state.dart';
import 'comment_row.dart';
import 'comments_skeleton.dart';
import 'more_comments_footer.dart';
import 'replies_link.dart';

/// The discussion under the post, as a sliver (C1–C6): the skeleton rows,
/// the empty block — its read-only words for a member who can't take part
/// yet — the error with its retry, or each comment with its replies and
/// their link, then the footer.
class CommunityCommentsSliver extends StatelessWidget {
  const CommunityCommentsSliver({super.key, required this.readOnly});

  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunityCommentsCubit, CommunityCommentsState>(
      builder: (context, state) {
        final cubit = context.read<CommunityCommentsCubit>();
        return switch (state.status) {
          CommunityCommentsStatus.loading => const SliverToBoxAdapter(
            child: CommentsSkeleton(),
          ),
          CommunityCommentsStatus.empty => SliverToBoxAdapter(
            child: _empty(context),
          ),
          CommunityCommentsStatus.failure => SliverToBoxAdapter(
            child: QeranErrorState(
              icon: Icons.cloud_off_rounded,
              title: LocaleKeys.community_comments_error.t(context),
              retryLabel: LocaleKeys.community_retry.t(context),
              onRetry: cubit.load,
            ),
          ),
          CommunityCommentsStatus.loaded => SliverList.list(
            children: [
              for (final thread in state.threads) ..._thread(thread, cubit),
              MoreCommentsFooter(state: state, onMore: cubit.loadMore),
            ],
          ),
        };
      },
    );
  }

  /// No comments yet (C4) — and for a read-only member, where they'll be.
  Widget _empty(BuildContext context) => QeranEmptyState(
    icon: Icons.forum_outlined,
    title: LocaleKeys.community_comments_empty_title.t(context),
    message:
        (readOnly
                ? LocaleKeys.community_comments_empty_read_only
                : LocaleKeys.community_comments_empty_body)
            .t(context),
  );

  /// A comment, the replies shown under it, and their link.
  List<Widget> _thread(CommentThread thread, CommunityCommentsCubit cubit) => [
    _row(thread.comment, cubit),
    for (final reply in thread.replies) _row(reply, cubit),
    RepliesLink(
      key: ValueKey('replies-${thread.id}'),
      thread: thread,
      onShow: () => cubit.showReplies(thread.id),
    ),
  ];

  Widget _row(CommunityComment comment, CommunityCommentsCubit cubit) =>
      CommentRow(
        key: ValueKey('comment-${comment.id}'),
        comment: comment,
        readOnly: readOnly,
        onLike: () => cubit.toggleLike(comment.id, readOnly: readOnly),
      );
}
