import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/connectivity/connectivity_cubit.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/block/presentation/blocs/block_action_cubit.dart';
import 'package:qeran/features/community/domain/entities/community_author.dart';
import 'package:qeran/features/community/domain/entities/community_config.dart';
import 'package:qeran/features/community/domain/entities/community_viewer.dart';
import 'package:qeran/features/community/domain/usecases/get_community_config_usecase.dart';
import 'package:qeran/features/community/presentation/blocs/comments/community_comments_cubit.dart';
import 'package:qeran/features/community/presentation/blocs/composer/community_composer_cubit.dart';
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
/// host. A Block goes through [block] (none answers by default).
Future<void> pumpPostScreen(
  WidgetTester tester,
  PostHarness post,
  CommentsHarness comments, {
  BlockCall? block,
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
          BlocProvider<CommunityComposerCubit>(
            create: (_) => composerOver(comments)..loadConfig(),
          ),
          BlocProvider<BlockActionCubit>(
            create: (_) => BlockActionCubit(block: block ?? _noBlock),
          ),
        ],
        child: CommunityPostScreen(viewer: viewer),
      ),
    ),
  );
}

Future<Either<Failure, void>> _noBlock(String _) =>
    throw StateError('nothing blocks in this test');

/// The member sending as [me].
const me = CommunityAuthor(
  id: 'member-9',
  displayName: 'Dima Alsafadi',
  isMatchmaker: false,
);

class _Config extends Fake implements GetCommunityConfigUseCase {
  @override
  Future<Either<Failure, CommunityConfig>> call() async =>
      const Right(CommunityConfig(commentMaxLength: 500));
}

/// A composer that sends through [comments] as [me], under a 500 limit.
CommunityComposerCubit composerOver(CommentsHarness comments) =>
    CommunityComposerCubit(
      getConfig: _Config(),
      send: (text, {parentId}) =>
          comments.cubit.send(text, parentId: parentId, me: me),
      retry: comments.cubit.retry,
    );

/// The card's own Like (the rows have theirs).
Finder get cardLike => find.descendant(
  of: find.byType(CommunityPostCard),
  matching: find.text('Like'),
);
