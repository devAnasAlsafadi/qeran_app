import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/state/account_scope.dart';
import 'package:qeran/features/badges/domain/entities/badge_tab_keys.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/features/community/domain/entities/community_viewer.dart';
import 'package:qeran/features/community/domain/usecases/get_my_community_posts_usecase.dart';
import 'package:qeran/features/community/presentation/blocs/guidelines/community_guidelines_cubit.dart';
import 'package:qeran/features/community/presentation/video/community_video_player.dart';
import 'package:qeran/features/community/presentation/video/video_player_adapter.dart';

import '../../shared/domain/ports/matchmaker_realtime_port.dart';
import '../presentation/blocs/composer/post_draft_cubit.dart';
import '../presentation/blocs/dashboard/community_dashboard_cubit.dart';
import '../presentation/blocs/composer/post_publish_cubit.dart';
import '../presentation/blocs/guidelines/matchmaker_guidelines_status.dart';
import '../presentation/blocs/my_posts/my_posts_cubit.dart';
import '../presentation/blocs/reports/community_reports_cubit.dart';
import '../presentation/services/community_media_picker.dart';

/// Her Community screens (Phase 3). Their data and domain are Community's,
/// registered with it; these are her cubits. Called by
/// `initMatchmakerDependencies`.
void initMatchmakerCommunityDependencies() {
  _initPosting();
  _initReports();

  // One per Community screen; opening «منشوراتي» clears her comments badge,
  // and her processing posts are watched until they're done.
  sl.registerFactory(
    () => MyPostsCubit(
      getMyPosts: sl<GetMyCommunityPostsUseCase>(),
      getPost: sl(),
      setPostLike: sl(),
      watchChanges: sl(),
      markCommentsSeen: () =>
          sl<BadgesCubit>().markSeen(BadgeTabKeys.communityComments),
      // Her shell keeps the connection for as long as she's signed in.
      statusChanges: sl<MatchmakerRealtimePort>().postStatusChanges,
    ),
  );
}

/// «البلاغات»: one per opening; what she keeps or deletes reads her badges
/// again (S16). And the Dashboard's section, one per Dashboard.
void _initReports() {
  sl.registerFactory(
    () => CommunityReportsCubit(
      getFlags: sl(),
      dismissFlag: sl(),
      deleteComment: sl(),
      onFlagCleared: () => sl<BadgesCubit>().refresh(),
    ),
  );
  // Her Dashboard's Community section: whether she has posts now (D35).
  sl.registerFactory(
    () => CommunityDashboardCubit(hasPosts: sl(), watchChanges: sl()),
  );
}

/// The guidelines step and her composer.
void _initPosting() {
  // Whether she still owes the posting guidelines; forgotten with her
  // account.
  sl.registerLazySingleton(
    () => sl<AccountScope>().hold(
      MatchmakerGuidelinesStatus(getMe: sl()),
      (status) => status.forget(),
    ),
  );
  // «إرشادات النشر»: agreeing tells her status, not the member's gate.
  sl.registerFactory<CommunityGuidelinesCubit>(
    () => CommunityGuidelinesCubit(
      getGuidelines: sl(),
      accept: sl(),
      onAccepted: sl<MatchmakerGuidelinesStatus>().markAccepted,
    ),
    instanceName: CommunityViewer.matchmaker.name,
  );
  _initComposer();
}

/// Her composer: the phone's picker and camera, her video's preview, the
/// draft against fresh limits, and its publishing.
void _initComposer() {
  sl.registerLazySingleton<CommunityMediaPicker>(
    ImagePickerCommunityMediaPicker.new,
  );
  sl.registerLazySingleton<CommunityLocalVideoPlayerFactory>(
    () => VideoPlayerAdapter.file,
  );
  sl.registerFactory(
    () => PostDraftCubit(
      getConfig: sl(),
      inspectImage: sl(),
      inspectVideo: sl(),
    ),
  );
  sl.registerFactory(() => PostPublishCubit(publish: sl()));
}
