import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../core/design_system/widgets/qeran_app_bar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../core/widgets/connectivity_banner_host.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../block/presentation/blocs/block_action_cubit.dart';
import '../../domain/entities/comment_submit_outcome.dart';
import '../../domain/entities/community_landing.dart';
import '../../domain/entities/community_post.dart';
import '../../domain/entities/community_viewer.dart';
import '../blocs/comments/community_comments_cubit.dart';
import '../blocs/composer/community_composer_cubit.dart';
import '../blocs/post/community_post_cubit.dart';
import '../blocs/post_delete/post_delete_cubit.dart';
import 'community_me.dart';
import 'community_post_screen.dart';
import 'post_delete_listener.dart';

/// Opens [postId]'s screen — from a feed card's discussion, with the card's
/// copy as [post] so it shows at once; from a notification, without one and
/// at its [landing] (C8). Both apps open it here. A `MaterialPageRoute`, so
/// iOS keeps its edge-swipe back. True when it closed on «العودة إلى المجتمع»
/// (C7, Q12): whoever opened it from a notification goes back to Community.
Future<bool> openCommunityPost(
  BuildContext context, {
  required int postId,
  CommunityPost? post,
  CommunityLanding? landing,
  CommunityViewer viewer = CommunityViewer.member,
}) async {
  final back = await Navigator.of(context).push(
    MaterialPageRoute<bool>(
      builder: (_) => CommunityPostPage(
        postId: postId,
        post: post,
        landing: landing,
        viewer: viewer,
      ),
    ),
  );
  return back ?? false;
}

/// The pushed post screen: «المنشور» on paper, and — offline — the banner
/// under it instead of over it (C11).
class CommunityPostPage extends StatelessWidget {
  const CommunityPostPage({
    super.key,
    required this.postId,
    this.post,
    this.landing,
    this.viewer = CommunityViewer.member,
  });

  final int postId;
  final CommunityPost? post;

  /// Where a notification lands in the discussion (C8).
  final CommunityLanding? landing;
  final CommunityViewer viewer;

  /// The composer sends through the comments, as this viewer — hers owes
  /// none of the member's steps.
  CommunityComposerCubit _composer(BuildContext context) {
    final comments = context.read<CommunityCommentsCubit>();
    Future<CommentSubmitOutcome?> send(String text, {int? parentId}) => comments
        .send(text, parentId: parentId, me: communityMe(context, viewer));
    return sl<CommunityComposerCubit>(
      param1: send,
      param2: comments.retry,
      instanceName: viewer == CommunityViewer.matchmaker ? viewer.name : null,
    )..loadConfig();
  }

  /// The post, its comments, the composer and — for a comment's Block —
  /// the block cubit, through Community (Q3).
  List<BlocProvider> get _providers => [
    BlocProvider<CommunityPostCubit>(
      create: (_) =>
          sl<CommunityPostCubit>(param1: postId, param2: post)..load(),
    ),
    BlocProvider<CommunityCommentsCubit>(
      create: (_) =>
          sl<CommunityCommentsCubit>(param1: postId, param2: landing)..load(),
    ),
    BlocProvider<CommunityComposerCubit>(create: _composer),
    BlocProvider<BlockActionCubit>(
      create: (_) => sl<BlockActionCubit>(param1: BlockOrigin.community),
    ),
    // Her own post's ⋮ (B6); a member never has one to delete.
    BlocProvider<PostDeleteCubit>(create: (_) => sl<PostDeleteCubit>()),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: _providers,
      child: PostDeleteListener(leaves: true, child: _scaffold(context)),
    );
  }

  Widget _scaffold(BuildContext context) => Scaffold(
    backgroundColor: QeranColors.creamCanvas,
    appBar: QeranAppBar(
      title: LocaleKeys.community_post_title.t(context),
      background: QeranColors.paper,
    ),
    body: AttachedConnectivityBanner(
      child: Column(
        children: [
          const ConnectivityBannerSlot(),
          Expanded(child: CommunityPostScreen(viewer: viewer)),
        ],
      ),
    ),
  );
}
