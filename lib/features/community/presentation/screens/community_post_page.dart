import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../core/design_system/widgets/qeran_app_bar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../core/widgets/connectivity_banner_host.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/entities/community_post.dart';
import '../../domain/entities/community_viewer.dart';
import '../blocs/comments/community_comments_cubit.dart';
import '../blocs/post/community_post_cubit.dart';
import 'community_post_screen.dart';

/// Opens [postId]'s screen — from a feed card's discussion, with the card's
/// copy as [post] so it shows at once; from a notification, without one.
/// Both apps open it here. A `MaterialPageRoute`, so iOS keeps its
/// edge-swipe back.
Future<void> openCommunityPost(
  BuildContext context, {
  required int postId,
  CommunityPost? post,
  CommunityViewer viewer = CommunityViewer.member,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) =>
        CommunityPostPage(postId: postId, post: post, viewer: viewer),
  ),
);

/// The pushed post screen: «المنشور» on paper, and — offline — the banner
/// under it instead of over it (C11).
class CommunityPostPage extends StatelessWidget {
  const CommunityPostPage({
    super.key,
    required this.postId,
    this.post,
    this.viewer = CommunityViewer.member,
  });

  final int postId;
  final CommunityPost? post;
  final CommunityViewer viewer;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CommunityPostCubit>(
          create: (_) =>
              sl<CommunityPostCubit>(param1: postId, param2: post)..load(),
        ),
        BlocProvider<CommunityCommentsCubit>(
          create: (_) => sl<CommunityCommentsCubit>(param1: postId)..load(),
        ),
      ],
      child: Scaffold(
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
      ),
    );
  }
}
