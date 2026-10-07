import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/community_page.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/domain/entities/community_post_change.dart';
import 'package:qeran/features/community/domain/repositories/community_author_repository.dart';
import 'package:qeran/features/community/domain/usecases/has_my_community_posts_usecase.dart';
import 'package:qeran/features/community/domain/usecases/watch_community_post_changes_usecase.dart';
import 'package:qeran/features/matchmaker/community/presentation/blocs/dashboard/community_dashboard_cubit.dart';

import '../../../community/fixtures/community_post_fixtures.dart';

class _MockRepository extends Mock implements CommunityAuthorRepository {}

class _MockWatch extends Mock implements WatchCommunityPostChangesUseCase {}

/// Her Dashboard's "no posts now" (D35).
void main() {
  late _MockRepository repository;
  late StreamController<CommunityPostChange> changes;
  late CommunityDashboardCubit section;

  void totalIs(int count) =>
      when(() => repository.getMyPosts(page: 1, pageSize: 1)).thenAnswer(
        (_) async => Right(
          CommunityPage<CommunityPost>(
            items: [if (count > 0) testPost()],
            pageNumber: 1,
            pageSize: 1,
            totalCount: count,
            totalPages: count,
          ),
        ),
      );

  setUp(() {
    repository = _MockRepository();
    changes = StreamController.broadcast();
    final watch = _MockWatch();
    when(watch.call).thenAnswer((_) => changes.stream);
    section = CommunityDashboardCubit(
      hasPosts: HasMyCommunityPostsUseCase(repository),
      watchChanges: watch,
    );
  });
  tearDown(() async {
    await section.close();
    await changes.close();
  });

  test('6.1 with one per page, read for its total: none, or some', () async {
    expect(section.state, isNull);
    totalIs(0);
    await section.load();
    expect(section.state, isFalse);

    totalIs(4);
    await section.load();
    expect(section.state, isTrue);
  });

  test('a failed read keeps what was known', () async {
    totalIs(0);
    await section.load();
    when(
      () => repository.getMyPosts(page: 1, pageSize: 1),
    ).thenAnswer((_) async => const Left(OfflineFailure()));

    await section.load();

    expect(section.state, isFalse);
  });

  test('a post she makes turns the rows on at once; one gone is read '
      'again — it may have been her last', () async {
    totalIs(0);
    await section.load();

    changes.add(CommunityPostCreated(testPost(id: 31)));
    await pumpEventQueue();
    expect(section.state, isTrue);

    changes.add(const CommunityPostGone(31));
    await pumpEventQueue();
    expect(section.state, isFalse);
  });
}
