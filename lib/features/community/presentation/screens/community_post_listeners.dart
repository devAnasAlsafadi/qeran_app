import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/block/presentation/blocs/block_action_cubit.dart';
import 'package:qeran/features/block/presentation/blocs/block_action_state.dart';

import '../../../../core/enum/snakebar_tybe.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../generated/locale_keys.g.dart';
import '../blocs/comments/community_comments_cubit.dart';
import '../blocs/comments/community_comments_state.dart';
import '../blocs/post/community_post_cubit.dart';
import '../blocs/post/community_post_state.dart';
import '../widgets/community_like_toast.dart';

/// What the post screen says once: a like that didn't go through (B13,
/// D9), a delete (E9, E10), a landing on content that's gone (C8), and a
/// block — whose rows leave the list while the screen stays (E12).
List<BlocListener> get communityPostListeners => [
  BlocListener<CommunityPostCubit, CommunityPostState>(
    listenWhen: _postEvent,
    listener: (context, state) => showCommunityLikeToast(
      context,
      readOnly:
          (state as CommunityPostReady).event ==
          CommunityPostEvent.readOnlyLike,
    ),
  ),
  BlocListener<CommunityCommentsCubit, CommunityCommentsState>(
    listenWhen: (previous, current) =>
        previous.eventVersion != current.eventVersion &&
        current.event != CommunityCommentsEvent.none,
    listener: (context, state) => _commentsToast(context, state.event),
  ),
  BlocListener<BlockActionCubit, BlockActionState>(
    listenWhen: (previous, current) =>
        previous.eventVersion != current.eventVersion &&
        current.outcome != BlockActionOutcome.none,
    listener: _blocked,
  ),
];

bool _postEvent(CommunityPostState previous, CommunityPostState current) {
  if (current is! CommunityPostReady) return false;
  if (current.event == CommunityPostEvent.none) return false;
  return previous is! CommunityPostReady ||
      previous.eventVersion != current.eventVersion;
}

void _commentsToast(BuildContext context, CommunityCommentsEvent event) {
  final (key, type) = switch (event) {
    CommunityCommentsEvent.deleted => (
      LocaleKeys.community_deleted,
      SnackBarType.success,
    ),
    CommunityCommentsEvent.deletedReply => (
      LocaleKeys.community_deleted_reply,
      SnackBarType.success,
    ),
    CommunityCommentsEvent.deleteFailed => (
      LocaleKeys.community_delete_failed,
      SnackBarType.error,
    ),
    CommunityCommentsEvent.contentGone => (
      LocaleKeys.community_content_gone,
      SnackBarType.info,
    ),
    _ => (null, null),
  };
  if (key == null || type == null) {
    return showCommunityLikeToast(
      context,
      readOnly: event == CommunityCommentsEvent.readOnlyLike,
    );
  }
  AppSnackBar.show(context, message: key.t(context), type: type);
}

/// Blocked (or gone — the same, never told apart): their rows go.
void _blocked(BuildContext context, BlockActionState state) {
  final id = state.blockedUserId;
  final done = state.outcome == BlockActionOutcome.success && id != null;
  if (done) context.read<CommunityCommentsCubit>().removeAuthor(id);
  AppSnackBar.show(
    context,
    message: (state.messageKey ?? LocaleKeys.errors_generic).t(context),
    type: done ? SnackBarType.success : SnackBarType.error,
  );
}
