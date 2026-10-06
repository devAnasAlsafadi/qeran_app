import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/state/account_scope.dart';
import 'package:qeran/features/community/data/datasources/community_author_refusing_datasource.dart';
import 'package:qeran/features/community/data/datasources/community_author_remote_datasource.dart';
import 'package:qeran/features/community/data/datasources/community_author_remote_datasource_impl.dart';
import 'package:qeran/features/community/data/datasources/community_remote_datasource.dart';
import 'package:qeran/features/community/data/repositories/community_post_changes.dart';
import 'package:qeran/features/community/di/community_author_injection.dart';
import 'package:qeran/features/community/di/community_injection.dart';
import 'package:qeran/features/community/domain/repositories/community_author_repository.dart';
import 'package:qeran/features/community/domain/usecases/delete_community_post_usecase.dart';
import 'package:qeran/features/community/domain/usecases/dismiss_community_flag_usecase.dart';
import 'package:qeran/features/community/domain/usecases/get_community_flags_usecase.dart';
import 'package:qeran/features/community/domain/usecases/get_my_community_posts_usecase.dart';
import 'package:qeran/features/profile/domain/usecases/get_my_profile_usecase.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';

import '../fixtures/community_mock_harness.dart';

class _MockApiConsumer extends Mock implements ApiConsumer {}

class _MockGetMyProfile extends Mock implements GetMyProfileUseCase {}

void main() {
  tearDown(sl.reset);

  test('registered with the member side: the live API, the repository '
      'and her four use cases', () {
    sl.registerSingleton<ApiConsumer>(_MockApiConsumer());
    sl.registerSingleton(AccountScope());
    sl.registerLazySingleton(
      () => ProfileGateCubit(getMyProfile: _MockGetMyProfile()),
    );

    initCommunityDependencies();

    expect(
      sl<CommunityAuthorRemoteDataSource>(),
      isA<CommunityAuthorRemoteDataSourceImpl>(),
    );
    expect(
      identical(
        sl<CommunityAuthorRepository>(),
        sl<CommunityAuthorRepository>(),
      ),
      isTrue,
    );
    expect(sl<GetMyCommunityPostsUseCase>(), isNotNull);
    expect(sl<DeleteCommunityPostUseCase>(), isNotNull);
    expect(sl<GetCommunityFlagsUseCase>(), isNotNull);
    expect(sl<DismissCommunityFlagUseCase>(), isNotNull);
  });

  test('when the member side is the dev-flag mock, every author call is '
      'refused, never sent live', () {
    sl.registerSingleton<ApiConsumer>(_MockApiConsumer());
    sl.registerSingleton(CommunityPostChanges());
    sl.registerSingleton<CommunityRemoteDataSource>(seededMock());

    initCommunityAuthorDependencies();

    expect(
      sl<CommunityAuthorRemoteDataSource>(),
      isA<CommunityAuthorRefusingDataSource>(),
    );
  });
}
