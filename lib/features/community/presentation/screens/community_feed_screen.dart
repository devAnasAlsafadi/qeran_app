import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/enum/snakebar_tybe.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../generated/locale_keys.g.dart';
import '../blocs/feed/community_feed_cubit.dart';
import '../blocs/feed/community_feed_state.dart';
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

/// The feed for the cubit in scope, and its toasts (B12, B13).
class CommunityFeedView extends StatelessWidget {
  const CommunityFeedView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CommunityFeedCubit, CommunityFeedState>(
      listenWhen: (previous, current) =>
          previous.eventVersion != current.eventVersion &&
          current.event != CommunityFeedEvent.none,
      listener: _onEvent,
      builder: (context, state) => CommunityFeedList(state: state),
    );
  }

  static void _onEvent(BuildContext context, CommunityFeedState state) {
    final (key, type) = switch (state.event) {
      CommunityFeedEvent.readOnlyLike => (
        LocaleKeys.community_read_only_like,
        SnackBarType.notice,
      ),
      _ => (LocaleKeys.community_like_failed, SnackBarType.error),
    };
    AppSnackBar.show(context, message: key.t(context), type: type);
  }
}
