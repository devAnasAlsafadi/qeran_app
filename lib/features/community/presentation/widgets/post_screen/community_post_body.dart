import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../domain/entities/community_post.dart';
import '../../blocs/post/community_post_cubit.dart';
import '../comments/comments_header.dart';
import '../comments/community_comments_sliver.dart';
import '../post_card/community_post_card.dart';

/// The post screen once the post is here (C1): the card with the whole text,
/// «النقاش» and its count, then the comments — one scroll.
class CommunityPostBody extends StatelessWidget {
  const CommunityPostBody({
    super.key,
    required this.post,
    required this.readOnly,
  });

  final CommunityPost post;

  /// A member who can read but not take part yet (D9).
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            QeranSpacing.s16,
            QeranSpacing.s12,
            QeranSpacing.s16,
            QeranSpacing.s4,
          ),
          sliver: SliverToBoxAdapter(child: _card(context)),
        ),
        SliverToBoxAdapter(child: CommentsHeader(count: post.commentCount)),
        CommunityCommentsSliver(readOnly: readOnly),
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.paddingOf(context).bottom + QeranSpacing.s24,
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context) => CommunityPostCard(
    post: post,
    mode: CommunityPostCardMode.detail,
    readOnly: readOnly,
    onLike: () =>
        context.read<CommunityPostCubit>().toggleLike(readOnly: readOnly),
  );
}
