import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/auth/presentation/reader_copy.dart';

import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../domain/entities/community_comment.dart';
import '../../../domain/entities/community_viewer.dart';
import '../../blocs/comments/comment_thread.dart';
import '../../blocs/comments/community_comments_cubit.dart';
import '../../blocs/comments/community_comments_state.dart';
import 'community_comment_item.dart';
import 'comments_skeleton.dart';
import 'more_comments_footer.dart';
import 'replies_link.dart';

/// The discussion under the post, as a sliver (C1–C6): the skeleton rows,
/// the empty block — its read-only words for a member who can't take part
/// yet — the error with its retry, or each comment with its replies and
/// their link, then the footer. A landing's row is in gold for a moment
/// (C8).
class CommunityCommentsSliver extends StatelessWidget {
  const CommunityCommentsSliver({
    super.key,
    required this.readOnly,
    required this.viewer,
  });

  final bool readOnly;

  /// Whose ⋮ options the rows offer (D40).
  final CommunityViewer viewer;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunityCommentsCubit, CommunityCommentsState>(
      builder: _sliver,
    );
  }

  Widget _sliver(BuildContext context, CommunityCommentsState state) {
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
          retryLabel: LocaleKeys.community_retry
              .forReader(her: LocaleKeys.community_her_retry)
              .t(context),
          onRetry: cubit.load,
        ),
      ),
      CommunityCommentsStatus.loaded => SliverList.list(
        children: [
          for (final thread in state.threads) ..._thread(state, thread, cubit),
          MoreCommentsFooter(state: state, onMore: cubit.loadMore),
        ],
      ),
    };
  }

  /// No comments yet (C4) — and for a read-only member, where they'll be.
  Widget _empty(BuildContext context) => QeranEmptyState(
    icon: Icons.forum_outlined,
    title: LocaleKeys.community_comments_empty_title.t(context),
    message:
        (readOnly
                ? LocaleKeys.community_comments_empty_read_only
                : LocaleKeys.community_comments_empty_body.forReader(
                    her: LocaleKeys.community_her_comments_empty_body,
                  ))
            .t(context),
  );

  /// A comment, the replies shown under it — a landing's, then the member's
  /// own, last — and their link.
  List<Widget> _thread(
    CommunityCommentsState state,
    CommentThread thread,
    CommunityCommentsCubit cubit,
  ) => [
    _item(state, thread.comment),
    for (final reply in [...thread.replies, ...thread.landed, ...thread.mine])
      _item(state, reply, parent: thread.comment),
    RepliesLink(
      key: ValueKey('replies-${thread.id}'),
      thread: thread,
      onShow: () => cubit.showReplies(thread.id),
    ),
  ];

  Widget _item(
    CommunityCommentsState state,
    CommunityComment comment, {
    CommunityComment? parent,
  }) => CommunityCommentItem(
    key: ValueKey('comment-${comment.id}'),
    comment: comment,
    parent: parent,
    delivery: state.delivery[comment.id],
    highlighted: comment.id == state.highlightId,
    readOnly: readOnly,
    viewer: viewer,
  );
}
