import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../blocs/feed/community_feed_cubit.dart';
import '../blocs/feed/community_feed_state.dart';
import '../video/community_stale_refresh.dart';
import '../video/community_video_scope.dart';
import '../widgets/community_like_toast.dart';
import '../widgets/feed/community_feed_list.dart';

/// The Community tab — where the member's app lands. Its cubit lives as long
/// as the tab, so the feed keeps its place across tab switches.
class CommunityFeedScreen extends StatelessWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CommunityFeedCubit>(
      create: (_) => sl<CommunityFeedCubit>()..load(),
      child: const CommunityFeedView(),
    );
  }
}

/// The feed for the cubit in scope, and its toasts (B12, B13). Its videos
/// take turns, and a feed kept past their links' 6 h reads itself again
/// (Q9, S19).
class CommunityFeedView extends StatelessWidget {
  const CommunityFeedView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CommunityFeedCubit>();
    return CommunityStaleRefresh(
      onStale: cubit.refresh,
      child: CommunityVideoScope(
        freshVideo: cubit.freshVideo,
        child: BlocConsumer<CommunityFeedCubit, CommunityFeedState>(
          listenWhen: (previous, current) =>
              previous.eventVersion != current.eventVersion &&
              current.event != CommunityFeedEvent.none,
          listener: _onEvent,
          builder: (context, state) => CommunityFeedList(state: state),
        ),
      ),
    );
  }

  static void _onEvent(BuildContext context, CommunityFeedState state) =>
      showCommunityLikeToast(
        context,
        readOnly: state.event == CommunityFeedEvent.readOnlyLike,
      );
}
