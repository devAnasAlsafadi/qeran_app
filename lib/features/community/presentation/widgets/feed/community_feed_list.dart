import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/auth/presentation/reader_copy.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_bottom_nav.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/design_system/widgets/qeran_section_header.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/widgets/paginated_list.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../../profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import '../../../domain/entities/community_post.dart';
import '../../../domain/entities/community_viewer.dart';
import '../../blocs/feed/community_feed_cubit.dart';
import '../../blocs/feed/community_feed_state.dart';
import '../../screens/community_post_page.dart';
import '../menus/community_post_menu.dart';
import '../post_card/community_post_card.dart';
import 'community_feed_footer.dart';
import 'community_feed_skeleton.dart';
import 'community_gate_notice.dart';

/// The feed as one scroll (B1–B10): the title and its subtitle, the gate
/// notice, then the posts and their footer — or the skeleton, the empty
/// state or the error state under the same title. Pull to refresh works in
/// every state; the end of the list asks for the next page.
///
/// A matchmaker [viewer] (her «كل المنشورات», Phase 3) gets no title and no
/// gate notice — her screen has its own header — is never read-only, and
/// opens posts as herself.
class CommunityFeedList extends StatelessWidget {
  const CommunityFeedList({
    super.key,
    required this.state,
    this.viewer = CommunityViewer.member,
    this.bottomClearance,
  });

  final CommunityFeedState state;
  final CommunityViewer viewer;

  /// The space kept free under the last card: the bottom nav's by default.
  final double? bottomClearance;

  bool get _member => viewer == CommunityViewer.member;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CommunityFeedCubit>();
    return PaginatedList(
      hasMore:
          state.status == CommunityFeedStatus.loaded &&
          state.hasMore &&
          !state.pageFailed,
      onRefresh: cubit.refresh,
      onLoadMore: cubit.loadMore,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (_member) ...const [
            SliverToBoxAdapter(child: _Header()),
            SliverToBoxAdapter(child: CommunityGateNotice()),
          ],
          ..._content(context, cubit),
          SliverToBoxAdapter(
            child: SizedBox(
              height:
                  bottomClearance ?? QeranBottomNav.contentClearance(context),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _content(BuildContext context, CommunityFeedCubit cubit) =>
      switch (state.status) {
        CommunityFeedStatus.initial || CommunityFeedStatus.loading => const [
          _Cards(
            children: [
              CommunityFeedSkeleton(),
              CommunityFeedSkeleton(withMedia: true),
            ],
          ),
        ],
        CommunityFeedStatus.empty => [
          _fill(
            QeranEmptyState(
              icon: Icons.auto_stories_rounded,
              title: LocaleKeys.community_feed_empty_title.t(context),
              message: LocaleKeys.community_feed_empty_body
                  .forReader(her: LocaleKeys.community_her_feed_empty_body)
                  .t(context),
            ),
          ),
        ],
        CommunityFeedStatus.failure => [_fill(_error(context, cubit))],
        CommunityFeedStatus.loaded => _loaded(cubit),
      };

  /// [child] in the space left under the title.
  static Widget _fill(Widget child) =>
      SliverFillRemaining(hasScrollBody: false, child: child);

  Widget _error(BuildContext context, CommunityFeedCubit cubit) =>
      QeranErrorState(
        icon: Icons.cloud_off_rounded,
        title: LocaleKeys.community_feed_error_title.t(context),
        message: LocaleKeys.community_feed_error_body
            .forReader(her: LocaleKeys.community_her_feed_error_body)
            .t(context),
        retryLabel: LocaleKeys.community_retry
            .forReader(her: LocaleKeys.community_her_retry)
            .t(context),
        onRetry: cubit.load,
      );

  /// The posts, then the footer.
  List<Widget> _loaded(CommunityFeedCubit cubit) => [
    _Cards(children: [for (final post in state.posts) _card(post)]),
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: QeranSpacing.s16),
        child: CommunityFeedFooter(state: state, onRetry: cubit.retryPage),
      ),
    ),
  ];

  Widget _card(CommunityPost post) => Builder(
    builder: (context) {
      // Only a member can be gated; hers is never read.
      final readOnly =
          _member &&
          context.select<ProfileGateCubit, bool>((gate) => gate.isGated);
      return CommunityPostCard(
        key: ValueKey(post.id),
        post: post,
        readOnly: readOnly,
        menu: communityPostMenu(post),
        onLike: () => context.read<CommunityFeedCubit>().toggleLike(
          post.id,
          readOnly: readOnly,
        ),
        onOpenDiscussion: () => openCommunityPost(
          context,
          postId: post.id,
          post: post,
          viewer: viewer,
        ),
      );
    },
  );
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s16,
        QeranSpacing.s20,
        QeranSpacing.s16,
      ),
      child: QeranSectionHeader(
        title: LocaleKeys.home_nav_community.t(context),
        subtitle: LocaleKeys.community_subtitle.t(context),
      ),
    );
  }
}

/// Cards 16 apart, 16 from the screen's edges.
class _Cards extends StatelessWidget {
  const _Cards({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s16),
      sliver: SliverList.separated(
        itemCount: children.length,
        itemBuilder: (_, i) => children[i],
        separatorBuilder: (_, _) => QeranSpacing.vs16,
      ),
    );
  }
}
