import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import '../../domain/entities/community_viewer.dart';
import '../blocs/comments/community_comments_cubit.dart';
import '../blocs/comments/community_comments_state.dart';
import '../blocs/post/community_post_cubit.dart';
import '../blocs/post/community_post_state.dart';
import '../widgets/comments/comments_skeleton.dart';
import '../widgets/community_like_toast.dart';
import '../widgets/composer/community_composer.dart';
import '../widgets/feed/community_feed_skeleton.dart';
import '../widgets/post_screen/community_post_body.dart';
import '../widgets/post_screen/community_post_unavailable.dart';

/// A post and its discussion, for the post and comments cubits in scope —
/// shared by both apps. A member whose profile isn't approved reads only
/// (D9); a matchmaker [viewer] is never gated.
class CommunityPostScreen extends StatelessWidget {
  const CommunityPostScreen({super.key, this.viewer = CommunityViewer.member});

  final CommunityViewer viewer;

  @override
  Widget build(BuildContext context) {
    final gated = context.select<ProfileGateCubit, bool>((g) => g.isGated);
    final readOnly = viewer == CommunityViewer.member && gated;
    return MultiBlocListener(
      listeners: _likeToasts,
      child: BlocBuilder<CommunityPostCubit, CommunityPostState>(
        builder: (context, state) => _body(context, state, readOnly),
      ),
    );
  }

  Widget _body(BuildContext context, CommunityPostState state, bool readOnly) =>
      switch (state) {
        CommunityPostLoading() => const _Loading(),
        CommunityPostReady(:final post) => Column(
          children: [
            Expanded(
              child: CommunityPostBody(post: post, readOnly: readOnly),
            ),
            CommunityComposer(readOnly: readOnly),
          ],
        ),
        CommunityPostRemoved() => CommunityPostUnavailable(
          onBack: () => Navigator.of(context).maybePop(),
        ),
        CommunityPostFailed() => QeranErrorState(
          icon: Icons.cloud_off_rounded,
          title: LocaleKeys.community_post_error_title.t(context),
          retryLabel: LocaleKeys.community_retry.t(context),
          onRetry: context.read<CommunityPostCubit>().load,
        ),
      };

  /// A like that didn't go through, on the post or on a comment.
  static List<BlocListener> get _likeToasts => [
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
      listener: (context, state) => showCommunityLikeToast(
        context,
        readOnly: state.event == CommunityCommentsEvent.readOnlyLike,
      ),
    ),
  ];

  static bool _postEvent(
    CommunityPostState previous,
    CommunityPostState current,
  ) {
    if (current is! CommunityPostReady) return false;
    if (current.event == CommunityPostEvent.none) return false;
    return previous is! CommunityPostReady ||
        previous.eventVersion != current.eventVersion;
  }
}

/// Opened without a copy of the post: a card's shape and three rows'.
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              QeranSpacing.s16,
              QeranSpacing.s12,
              QeranSpacing.s16,
              QeranSpacing.s16,
            ),
            child: CommunityFeedSkeleton(),
          ),
          CommentsSkeleton(),
        ],
      ),
    );
  }
}
