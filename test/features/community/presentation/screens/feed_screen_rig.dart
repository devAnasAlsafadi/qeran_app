import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/connectivity/connectivity_cubit.dart';
import 'package:qeran/core/services/connectivity_service.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/community/domain/entities/community_viewer.dart';
import 'package:qeran/features/community/presentation/blocs/feed/community_feed_cubit.dart';
import 'package:qeran/features/community/presentation/screens/community_feed_screen.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../../profile/presentation/fake_profile_gate.dart';
import '../blocs/feed/feed_cubit_harness.dart';

/// Always online: the error state reads the connection.
class _Online implements ConnectivityService {
  @override
  Future<bool> get isOnline async => true;
  @override
  Stream<bool> get onStatusChange => const Stream<bool>.empty();
}

/// Both UI languages, and what each one writes.
final feedLocales = {
  const Locale('ar'): (
    title: 'المجتمع',
    subtitle: 'إرشادات تنشرها خطّابات قِران',
    end: 'لا توجد منشورات أخرى',
    emptyTitle: 'لا توجد منشورات بعد',
    errorTitle: 'تعذّر تحميل المنشورات',
    retry: 'حاول مرة أخرى',
    pageError: 'تعذّر تحميل المزيد.',
    pageRetry: 'إعادة المحاولة',
    like: 'إعجاب',
  ),
  const Locale('en'): (
    title: 'Community',
    subtitle: 'Guidance published by Qeran’s matchmakers',
    end: 'No more posts',
    emptyTitle: 'No posts yet',
    errorTitle: 'Couldn’t load posts',
    retry: 'Try again',
    pageError: 'Couldn’t load more.',
    pageRetry: 'Retry',
    like: 'Like',
  ),
};

/// The feed of [h]'s cubit, as the [viewer] at [gate] sees it, on a phone
/// [size] (logical points), with the toast host. [gateCubit] replaces the
/// gate at [gate] — e.g. one that fails if it's ever read.
Future<void> pumpFeed(
  WidgetTester tester,
  FeedHarness h, {
  Locale locale = const Locale('en'),
  ProfileStatus? gate = ProfileStatus.visible,
  ProfileGateCubit? gateCubit,
  CommunityViewer viewer = CommunityViewer.member,
  Size size = const Size(390, 1200),
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
          BlocProvider<ProfileGateCubit>.value(
            value: gateCubit ?? FakeGate(gate),
          ),
          BlocProvider<ConnectivityCubit>(
            create: (_) => ConnectivityCubit(service: _Online()),
          ),
          BlocProvider<CommunityFeedCubit>.value(value: h.cubit),
        ],
        child: CommunityFeedView(viewer: viewer),
      ),
    ),
  );
}
