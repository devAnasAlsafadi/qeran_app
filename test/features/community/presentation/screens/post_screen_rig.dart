import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/connectivity/connectivity_cubit.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/community/domain/entities/community_viewer.dart';
import 'package:qeran/features/community/presentation/blocs/comments/community_comments_cubit.dart';
import 'package:qeran/features/community/presentation/blocs/post/community_post_cubit.dart';
import 'package:qeran/features/community/presentation/screens/community_post_screen.dart';
import 'package:qeran/features/community/presentation/widgets/post_card/community_post_card.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../../profile/presentation/fake_profile_gate.dart';
import '../../fixtures/community_mock_harness.dart';
import '../blocs/comments/comments_cubit_harness.dart';
import '../blocs/post/post_cubit_harness.dart';

/// The post screen over [post]'s and [comments]' cubits, as the [viewer]
/// at [gate] sees it, on a phone [size] (logical points), with the toast
/// host.
Future<void> pumpPostScreen(
  WidgetTester tester,
  PostHarness post,
  CommentsHarness comments, {
  Locale locale = const Locale('en'),
  ProfileStatus? gate = ProfileStatus.visible,
  CommunityViewer viewer = CommunityViewer.member,
  Size size = const Size(390, 1600),
  bool settle = true,
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  addTearDown(AppSnackBar.debugReset);
  return pumpShippedStrings(
    tester,
    locale,
    settle: settle,
    child: AppSnackBarHost(
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ProfileGateCubit>.value(value: FakeGate(gate)),
          BlocProvider<ConnectivityCubit>(
            create: (_) => ConnectivityCubit(service: FakeConnectivity()),
          ),
          BlocProvider<CommunityPostCubit>.value(value: post.cubit),
          BlocProvider<CommunityCommentsCubit>.value(value: comments.cubit),
        ],
        child: CommunityPostScreen(viewer: viewer),
      ),
    ),
  );
}

/// The card's own Like (the rows have theirs).
Finder get cardLike => find.descendant(
  of: find.byType(CommunityPostCard),
  matching: find.text('Like'),
);
