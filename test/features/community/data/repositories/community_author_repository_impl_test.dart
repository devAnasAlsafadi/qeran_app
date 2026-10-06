import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/community/data/datasources/community_author_remote_datasource.dart';
import 'package:qeran/features/community/data/models/community_flagged_item_model.dart';
import 'package:qeran/features/community/data/models/community_page_model.dart';
import 'package:qeran/features/community/data/models/community_post_model.dart';
import 'package:qeran/features/community/data/repositories/community_author_repository_impl.dart';
import 'package:qeran/features/community/data/repositories/community_post_changes.dart';
import 'package:qeran/features/community/data/repositories/community_repository_impl.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/domain/entities/community_post_change.dart';
import 'package:qeran/features/community/domain/entities/post_publish_outcome.dart';

import '../../fixtures/community_fixtures.dart';
import '../../fixtures/community_mock_harness.dart';

class _MockDataSource extends Mock implements CommunityAuthorRemoteDataSource {}

T _right<T>(Either<Failure, T> e) => e.fold((f) => fail('Left: $f'), (r) => r);

CodedServerException _coded(String code) =>
    CodedServerException(message: 'x', errorCode: code);

void main() {
  late _MockDataSource ds;
  late CommunityPostChanges changes;
  late CommunityAuthorRepositoryImpl repo;
  late List<CommunityPostChange> heard;
  late StreamSubscription<CommunityPostChange> listening;

  setUp(() {
    ds = _MockDataSource();
    changes = CommunityPostChanges();
    repo = CommunityAuthorRepositoryImpl(ds, changes: changes);
    heard = [];
    listening = changes.stream.listen(heard.add);
  });
  tearDown(() => listening.cancel());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('her posts: every status, as the server sent them', () async {
    when(() => ds.getMyPosts(page: 1, pageSize: 20)).thenAnswer(
      (_) async => CommunityPageModel.fromJson(
        paged([post(id: 9, status: 'Processing'), post(id: 8)]),
        CommunityPostModel.fromJson,
      ),
    );

    final page = _right(await repo.getMyPosts(page: 1, pageSize: 20));

    expect(page.items.map((p) => p.status), [
      CommunityPostStatus.processing,
      CommunityPostStatus.published,
    ]);
  });

  group('delete', () {
    test('done: the post is announced gone', () async {
      when(() => ds.deletePost(5)).thenAnswer((_) async {});

      expect(_right(await repo.deletePost(5)), unit);
      await settle();

      expect(heard.single, isA<CommunityPostGone>());
      expect(heard.single.postId, 5);
    });

    test('already gone (POST_NOT_FOUND) is what she asked for', () async {
      when(() => ds.deletePost(5)).thenThrow(_coded('POST_NOT_FOUND'));

      expect(_right(await repo.deletePost(5)), unit);
      await settle();

      expect(heard.single, isA<CommunityPostGone>());
    });

    test('offline, or not hers: a failure, and the post stays', () async {
      when(() => ds.deletePost(5)).thenThrow(OfflineException());
      expect((await repo.deletePost(5)).isLeft(), isTrue);

      when(() => ds.deletePost(6)).thenThrow(_coded('UNAUTHORIZED'));
      final notHers = await repo.deletePost(6);
      await settle();

      expect(
        notHers.fold((f) => (f as CodedServerFailure).errorCode, (_) => null),
        'UNAUTHORIZED',
      );
      expect(heard, isEmpty);
    });
  });

  test('flags: a row with no flag at all is left out', () async {
    when(() => ds.getFlags(page: 1, pageSize: 20)).thenAnswer(
      (_) async => CommunityPageModel.fromJson(
        paged([
          {
            'flag': {'id': 77, 'reportCount': 1, 'reasons': const []},
            'comment': comment(),
            'post': {'id': 123, 'textSnippet': 'نص'},
          },
          {'flag': null, 'comment': comment(id: 457), 'post': null},
        ]),
        CommunityFlaggedItemModel.fromJson,
      ),
    );

    final page = _right(await repo.getFlags(page: 1, pageSize: 20));

    expect(page.items.single.flag.id, 77);
    expect(page.totalPages, 2);
  });

  test('a row without its own flag takes the comment\'s copy', () {
    final row = CommunityFlaggedItemModel.fromJson({
      'comment': {
        ...comment(),
        'flag': {'id': 5, 'reportCount': 1, 'reasons': const []},
      },
    }).toEntity();

    expect(row?.flag.id, 5);
    expect(row?.postId, 123);
    expect(row?.postSnippet, '');
  });

  test('dismiss: done, or the server\'s failure', () async {
    when(() => ds.dismissFlag(77)).thenAnswer((_) async {});
    expect(_right(await repo.dismissFlag(77)), unit);

    when(() => ds.dismissFlag(78)).thenThrow(OfflineException());
    expect(await repo.dismissFlag(78), const Left(OfflineFailure()));
  });

  test('one stream for both repositories: her delete reaches the '
      'member-side stream the feed and post screen listen to', () async {
    final member = CommunityRepositoryImpl(
      seededMock(accepted: true),
      changes: changes,
    );
    final next = member.postChanges.first;
    when(() => ds.deletePost(5)).thenAnswer((_) async {});

    await repo.deletePost(5);

    expect((await next).postId, 5);
  });

  group('publish (6.2)', () {
    Future<Either<Failure, PostPublishOutcome>> publish() =>
        repo.createPost(text: 'إرشاد', clientRequestId: 'req-1');

    test('made: the post, announced to every list', () async {
      when(
        () => ds.createPost(text: 'إرشاد', clientRequestId: 'req-1'),
      ).thenAnswer((_) async => CommunityPostModel.fromJson(post(id: 31)));

      final outcome = _right(await publish());
      await settle();

      expect((outcome as PostPublished).post.id, 31);
      expect(heard.single, isA<CommunityPostCreated>());
    });

    test('the filter, and new guidelines, are outcomes; nothing is '
        'announced', () async {
      when(
        () => ds.createPost(text: 'إرشاد', clientRequestId: 'req-1'),
      ).thenThrow(_coded('CONTENT_NOT_ALLOWED'));
      expect(_right(await publish()), isA<PostRejected>());

      when(
        () => ds.createPost(text: 'إرشاد', clientRequestId: 'req-1'),
      ).thenThrow(_coded('COMMUNITY_GUIDELINES_NOT_ACCEPTED'));
      expect(_right(await publish()), isA<PostGuidelinesRequired>());
      await settle();

      expect(heard, isEmpty);
    });

    test('offline, or any other code: a failure (the failed strip)', () async {
      when(
        () => ds.createPost(text: 'إرشاد', clientRequestId: 'req-1'),
      ).thenThrow(OfflineException());
      expect(await publish(), const Left(OfflineFailure()));

      when(
        () => ds.createPost(text: 'إرشاد', clientRequestId: 'req-1'),
      ).thenThrow(_coded('VALIDATION_ERROR'));
      expect((await publish()).isLeft(), isTrue);
    });
  });
}
