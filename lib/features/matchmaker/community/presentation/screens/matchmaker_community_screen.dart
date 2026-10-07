import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/community/domain/entities/community_viewer.dart';
import 'package:qeran/features/community/presentation/blocs/feed/community_feed_cubit.dart';
import 'package:qeran/features/community/presentation/blocs/post_delete/post_delete_cubit.dart';
import 'package:qeran/features/community/presentation/screens/community_feed_screen.dart';
import 'package:qeran/features/community/presentation/screens/post_delete_listener.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_app_bar.dart';
import '../../../../../core/design_system/widgets/qeran_floating_button.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/widgets/connectivity_banner_host.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_segmented_tabs.dart';
import '../blocs/my_posts/my_posts_cubit.dart';
import '../widgets/community_new_post_button.dart';
import '../widgets/my_posts_states.dart';
import '../widgets/published_toast.dart';
import 'start_new_post.dart';

/// Her Community screen's two segments.
enum MatchmakerCommunityTab { all, mine }

/// Opens her Community screen on [tab] — from the header icon (A1) on «كل
/// المنشورات». A `MaterialPageRoute`, so iOS keeps its edge-swipe back.
Future<void> openMatchmakerCommunity(
  BuildContext context, {
  MatchmakerCommunityTab tab = MatchmakerCommunityTab.all,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => MatchmakerCommunityScreen(initialTab: tab),
  ),
);

/// «المجتمع» in her app (B1–B5): «كل المنشورات», the shared feed as she
/// reads it (D8), and «منشوراتي», her posts in every status. Each keeps its
/// place across switches; «منشوراتي» loads the first time it's opened, and
/// every opening clears her new-comments count (D33).
class MatchmakerCommunityScreen extends StatefulWidget {
  const MatchmakerCommunityScreen({
    super.key,
    this.initialTab = MatchmakerCommunityTab.all,
  });

  final MatchmakerCommunityTab initialTab;

  @override
  State<MatchmakerCommunityScreen> createState() =>
      _MatchmakerCommunityScreenState();
}

class _MatchmakerCommunityScreenState extends State<MatchmakerCommunityScreen>
    with WidgetsBindingObserver {
  late final CommunityFeedCubit _all = sl<CommunityFeedCubit>()..load();
  late final MyPostsCubit _mine = sl<MyPostsCubit>();

  /// Her own post's ⋮ on either list (B6–B9).
  late final PostDeleteCubit _deleting = sl<PostDeleteCubit>();
  late MatchmakerCommunityTab _tab = widget.initialTab;

  /// «منشوراتي» is built, and read, only once she opens it.
  bool _mineOpened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_tab == MatchmakerCommunityTab.mine) _openMine();
  }

  /// Back in front: whatever finished processing meanwhile shows now.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _mineOpened) {
      _mine.checkProcessing();
    }
  }

  void _select(int index) {
    final tab = MatchmakerCommunityTab.values[index];
    if (tab == _tab) return;
    setState(() => _tab = tab);
    if (tab == MatchmakerCommunityTab.mine) _openMine();
  }

  void _openMine() {
    if (!_mineOpened) {
      _mineOpened = true;
      _mine.load();
    }
    _mine.seen();
  }

  /// «منشور جديد» (B1, B4): once published she lands on «منشوراتي», her
  /// post first (Q7, D5); a video's says it shows once processed (D4).
  Future<void> _newPost() async {
    final post = await startNewPost(context);
    if (post == null || !mounted) return;
    _select(MatchmakerCommunityTab.mine.index);
    showPublishedToast(context, post);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _all.close();
    _mine.close();
    _deleting.close();
    super.dispose();
  }

  static const _segmentLabels = [
    MatchmakerSegment(labelKey: LocaleKeys.matchmaker_community_all_posts),
    MatchmakerSegment(labelKey: LocaleKeys.matchmaker_community_my_posts),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: QeranAppBar(
        title: LocaleKeys.matchmaker_community_title.t(context),
      ),
      floatingActionButton: CommunityNewPostButton(
        mine: _mine,
        onMine: _tab == MatchmakerCommunityTab.mine,
        onPressed: _newPost,
      ),
      body: AttachedConnectivityBanner(
        child: Column(
          children: [
            const ConnectivityBannerSlot(),
            MatchmakerSegmentedTabs(
              activeIndex: _tab.index,
              onChanged: _select,
              segments: _segmentLabels,
            ),
            Expanded(child: _deletable(context)),
          ],
        ),
      ),
    );
  }

  /// Her deletes, from either segment, speak through one cubit (B6–B9).
  Widget _deletable(BuildContext context) => BlocProvider.value(
    value: _deleting,
    child: PostDeleteListener(child: _segments(context)),
  );

  Widget _segments(BuildContext context) {
    final clearance = QeranFloatingButton.clearance(context);
    return IndexedStack(
      index: _tab.index,
      sizing: StackFit.expand,
      children: [
        BlocProvider<CommunityFeedCubit>.value(
          value: _all,
          child: CommunityFeedView(
            viewer: CommunityViewer.matchmaker,
            bottomClearance: clearance,
          ),
        ),
        if (_mineOpened)
          BlocProvider<CommunityFeedCubit>.value(
            value: _mine,
            child: CommunityFeedView(
              viewer: CommunityViewer.matchmaker,
              bottomClearance: clearance,
              empty: myPostsEmpty(_newPost),
              error: myPostsError,
            ),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}
