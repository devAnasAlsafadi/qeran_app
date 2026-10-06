import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/badges/domain/entities/badge_tab_keys.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/features/community/domain/usecases/get_my_community_posts_usecase.dart';

import '../presentation/blocs/my_posts/my_posts_cubit.dart';

/// Her Community screens (Phase 3). Their data and domain are Community's,
/// registered with it; these are her cubits. Called by
/// `initMatchmakerDependencies`.
void initMatchmakerCommunityDependencies() {
  // One per Community screen; opening «منشوراتي» clears her comments badge.
  sl.registerFactory(
    () => MyPostsCubit(
      getMyPosts: sl<GetMyCommunityPostsUseCase>(),
      getPost: sl(),
      setPostLike: sl(),
      watchChanges: sl(),
      markCommentsSeen: () =>
          sl<BadgesCubit>().markSeen(BadgeTabKeys.communityComments),
    ),
  );
}
