import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/state/account_scope.dart';
import 'package:qeran/features/community/data/datasources/community_remote_datasource.dart';
import 'package:qeran/features/community/data/datasources/community_remote_datasource_impl.dart';
import 'package:qeran/features/community/data/datasources/mock/community_mock_mode.dart';
import 'package:qeran/features/community/data/repositories/community_post_changes.dart';
import 'package:qeran/features/community/di/community_injection.dart';
import 'package:qeran/features/community/domain/entities/community_post_change.dart';
import 'package:qeran/features/community/domain/entities/community_viewer.dart';
import 'package:qeran/features/community/domain/entities/comment_submit_outcome.dart';
import 'package:qeran/features/community/domain/repositories/community_repository.dart';
import 'package:qeran/features/community/domain/usecases/block_community_member_usecase.dart';
import 'package:qeran/features/community/domain/usecases/get_community_feed_usecase.dart';
import 'package:qeran/features/community/domain/usecases/report_community_content_usecase.dart';
import 'package:qeran/features/community/presentation/blocs/comments/community_comments_cubit.dart';
import 'package:qeran/features/community/presentation/blocs/comments/community_comments_state.dart';
import 'package:qeran/features/community/presentation/blocs/composer/community_composer_cubit.dart';
import 'package:qeran/features/community/presentation/blocs/composer/community_gate.dart';
import 'package:qeran/features/community/presentation/blocs/post/community_post_cubit.dart';
import 'package:qeran/features/community/presentation/blocs/post/community_post_state.dart';
import 'package:qeran/features/profile/domain/entities/my_profile.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';
import 'package:qeran/features/profile/domain/usecases/get_my_profile_usecase.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/block/domain/repositories/community_member_blocker.dart';
import 'package:qeran/features/report/domain/repositories/content_reporter.dart';

class _MockApiConsumer extends Mock implements ApiConsumer {}

class _MockGetMyProfile extends Mock implements GetMyProfileUseCase {}

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
    // The app's profile gate, registered by the profile feature, and the
    // account scope the repository joins, registered by the container.
    setUp(() {
      sl.registerSingleton<ApiConsumer>(_MockApiConsumer());
      sl.registerSingleton(AccountScope());
      sl.registerLazySingleton(
        () => ProfileGateCubit(getMyProfile: _MockGetMyProfile()),
      );
    });
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

    test("the repository speaks on the app's one change stream, which the "
        "author's repository shares", () async {
      initCommunityDependencies();
      final heard = sl<CommunityRepository>().postChanges.first;

      sl<CommunityPostChanges>().add(const CommunityPostGone(5));

      expect(
        await heard,
        isA<CommunityPostGone>().having((c) => c.postId, 'postId', 5),
      );
      expect(
        identical(sl<CommunityPostChanges>(), sl<CommunityPostChanges>()),
        isTrue,
      );
    });

    test("the report and block paths for content are Community's (Q3)", () {
      initCommunityDependencies();

      expect(sl<ContentReporter>(), isA<ReportCommunityContentUseCase>());
      expect(
        sl<CommunityMemberBlocker>(),
        isA<BlockCommunityMemberUseCase>(),
      );
    });

    test('the post screen\'s cubits, for a post id — with or without the '
        'feed\'s copy', () async {
      initCommunityDependencies();

      final post = sl<CommunityPostCubit>(param1: 7, param2: null);
      final comments = sl<CommunityCommentsCubit>(param1: 7);

      Future<CommentSubmitOutcome?> send(String text, {int? parentId}) async =>
          null;
      final composer = sl<CommunityComposerCubit>(
        param1: send,
        param2: comments.retry,
      );

      expect(post.state, const CommunityPostLoading());
      expect(comments.state.status, CommunityCommentsStatus.loading);
      expect(composer.state.replyTo, isNull);
      await post.close();
      await comments.close();
      await composer.close();
    });

    test("the composer asks the app's profile gate what is owed", () async {
      initCommunityDependencies();
      sl<ProfileGateCubit>().applyProfile(
        const MyProfile(
          id: 'u-1',
          name: 'مستخدم',
          isDefaultName: true,
          email: null,
          gender: 'Female',
          birthDate: null,
          age: 28,
          profileStatus: ProfileStatus.visible,
          hasAnsweredQuestions: true,
          profileImage: null,
          images: [],
          placements: [],
        ),
      );
      Future<CommentSubmitOutcome?> send(String text, {int? parentId}) async =>
          null;
      Future<CommentSubmitOutcome?> retry(int id) async => null;

      final composer = sl<CommunityComposerCubit>(param1: send, param2: retry);

      expect(composer.state.owes, CommunityGate.name);
      await composer.close();
    });

    test('hers owes nothing, whatever the member gate says (K21)', () async {
      initCommunityDependencies();
      sl<ProfileGateCubit>().applyProfile(
        const MyProfile(
          id: 'u-1',
          name: 'مستخدم',
          isDefaultName: true,
          email: null,
          gender: 'Female',
          birthDate: null,
          age: 28,
          profileStatus: ProfileStatus.pendingReview,
          hasAnsweredQuestions: true,
          profileImage: null,
          images: [],
          placements: [],
        ),
      );
      Future<CommentSubmitOutcome?> send(String text, {int? parentId}) async =>
          null;
      Future<CommentSubmitOutcome?> retry(int id) async => null;

      final composer = sl<CommunityComposerCubit>(
        param1: send,
        param2: retry,
        instanceName: CommunityViewer.matchmaker.name,
      );

      expect(composer.state.owes, isNull);
      await composer.close();
    });
  });
}
