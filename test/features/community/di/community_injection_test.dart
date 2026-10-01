import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/community/data/datasources/community_remote_datasource.dart';
import 'package:qeran/features/community/data/datasources/community_remote_datasource_impl.dart';
import 'package:qeran/features/community/data/datasources/mock/community_mock_mode.dart';
import 'package:qeran/features/community/di/community_injection.dart';
import 'package:qeran/features/community/domain/repositories/community_repository.dart';
import 'package:qeran/features/community/domain/usecases/get_community_feed_usecase.dart';

class _MockApiConsumer extends Mock implements ApiConsumer {}

void main() {
  group('CommunityMockMode.fromFlag', () {
    test('the four dev states, any case or spacing', () {
      expect(CommunityMockMode.fromFlag('seeded'), CommunityMockMode.seeded);
      expect(CommunityMockMode.fromFlag(' EMPTY '), CommunityMockMode.empty);
      expect(CommunityMockMode.fromFlag('errors'), CommunityMockMode.errors);
      expect(CommunityMockMode.fromFlag('slow'), CommunityMockMode.slow);
    });

    test('no flag, or an unknown one, means the live API', () {
      expect(CommunityMockMode.fromFlag(''), isNull);
      expect(CommunityMockMode.fromFlag('mock'), isNull);
    });
  });

  group('initCommunityDependencies', () {
    setUp(() => sl.registerSingleton<ApiConsumer>(_MockApiConsumer()));
    tearDown(sl.reset);

    // Tests run without --dart-define, as a release build always does in
    // effect (the mock branch is compiled out there): the live API is wired.
    test('without the flag, the live datasource is registered', () {
      initCommunityDependencies();

      expect(sl<CommunityRemoteDataSource>(),
          isA<CommunityRemoteDataSourceImpl>());
    });

    test('one repository for the app, so postChanges is shared', () {
      initCommunityDependencies();

      expect(identical(sl<CommunityRepository>(), sl<CommunityRepository>()),
          isTrue);
      expect(sl<GetCommunityFeedUseCase>(), isNotNull);
    });
  });
}
