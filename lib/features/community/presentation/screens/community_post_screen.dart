import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/auth/presentation/reader_copy.dart';

import '../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import '../../domain/entities/community_viewer.dart';
import '../blocs/post/community_post_cubit.dart';
import '../blocs/post/community_post_state.dart';
import '../blocs/post_delete/post_delete_cubit.dart';
import '../widgets/comments/comments_skeleton.dart';
import '../widgets/composer/community_composer.dart';
import '../widgets/feed/community_feed_skeleton.dart';
import '../widgets/post_screen/community_post_body.dart';
import '../widgets/post_screen/community_post_unavailable.dart';
import 'community_post_listeners.dart';

/// A post and its discussion, for the post and comments cubits in scope —
/// shared by both apps. A member whose profile isn't approved reads only
/// (D9); a matchmaker [viewer] is never gated. The post gone, and it is no
/// longer available (C7).
class CommunityPostScreen extends StatelessWidget {
  const CommunityPostScreen({super.key, this.viewer = CommunityViewer.member});

  final CommunityViewer viewer;

  @override
  Widget build(BuildContext context) {
    // Only a member can be gated; hers is never read.
    final readOnly =
        viewer == CommunityViewer.member &&
        context.select<ProfileGateCubit, bool>((g) => g.isGated);
    return MultiBlocListener(
      listeners: communityPostListeners,
      child: BlocBuilder<CommunityPostCubit, CommunityPostState>(
        // Her own delete closes the screen: it never shows her post as gone
        // on the way out (S8).
        buildWhen: (_, current) =>
            current is! CommunityPostRemoved ||
            !context.read<PostDeleteCubit>().state.leaving,
        builder: (context, state) => _body(context, state, readOnly),
      ),
    );
  }

  /// «العودة إلى المجتمع» closes the post saying so (Q12).
  Widget _unavailable(BuildContext context) => CommunityPostUnavailable(
    onBack: () => Navigator.of(context).maybePop(true),
  );

  Widget _body(BuildContext context, CommunityPostState state, bool readOnly) =>
      switch (state) {
        CommunityPostLoading() => const _Loading(),
        CommunityPostReady(:final post) => Column(
          children: [
            Expanded(
              child: CommunityPostBody(
                post: post,
                readOnly: readOnly,
                viewer: viewer,
              ),
            ),
            CommunityComposer(readOnly: readOnly),
          ],
        ),
        CommunityPostRemoved() => _unavailable(context),
        CommunityPostFailed() => QeranErrorState(
          icon: Icons.cloud_off_rounded,
          title: LocaleKeys.community_post_error_title.t(context),
          retryLabel: LocaleKeys.community_retry
              .forReader(her: LocaleKeys.community_her_retry)
              .t(context),
          onRetry: context.read<CommunityPostCubit>().load,
        ),
      };
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
