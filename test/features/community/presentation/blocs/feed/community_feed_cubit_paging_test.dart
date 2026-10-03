import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/community_page.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/presentation/blocs/feed/community_feed_state.dart';

import 'feed_cubit_harness.dart';

List<int> _ids(FeedHarness h) => [for (final p in h.cubit.state.posts) p.id];

void main() {
  late FeedHarness h;
  setUp(() => h = FeedHarness());
  tearDown(() => h.dispose());

  group('the first page', () {
    test('posts → loaded (B1)', () async {
      h.page(1, posts(1, 3), totalPages: 2);

      await h.cubit.load();

      expect(h.cubit.state.status, CommunityFeedStatus.loaded);
      expect(_ids(h), [1, 2, 3]);
      expect(h.cubit.state.hasMore, isTrue);
    });

    test('none → empty (B4)', () async {
      h.page(1, const []);

      await h.cubit.load();

      expect(h.cubit.state.status, CommunityFeedStatus.empty);
    });

    test(
      'a failure → the error state, and its retry loads again (B5)',
      () async {
        h.pageFails(1);
        await h.cubit.load();
        expect(h.cubit.state.status, CommunityFeedStatus.failure);

        h.page(1, posts(1, 2));
        await h.cubit.load();
        expect(h.cubit.state.status, CommunityFeedStatus.loaded);
      },
    );
  });

  group('the next page', () {
    setUp(() async {
      h.page(1, posts(1, 3), totalPages: 3);
      await h.cubit.load();
    });

    test('adds what it hasn\'t got (a post published meanwhile shifts the '
        'pages)', () async {
      h.page(2, posts(3, 5), totalPages: 3);

      await h.cubit.loadMore();

      expect(_ids(h), [1, 2, 3, 4, 5]);
      expect(h.cubit.state.page, 2);
    });

    test('a failure stops asking until its retry (B9)', () async {
      h.pageFails(2);
      await h.cubit.loadMore();
      expect(h.cubit.state.pageFailed, isTrue);

      await h.cubit.loadMore();
      verify(() => h.getFeed(page: 2)).called(1);

      h.page(2, posts(4, 5), totalPages: 3);
      await h.cubit.retryPage();
      expect(h.cubit.state.pageFailed, isFalse);
      expect(_ids(h), [1, 2, 3, 4, 5]);
    });

    test('the last page ends the feed (B10)', () async {
      h.page(2, posts(4, 5), totalPages: 2);

      await h.cubit.loadMore();
      await h.cubit.loadMore();

      expect(h.cubit.state.reachedEnd, isTrue);
      verifyNever(() => h.getFeed(page: 3));
    });
  });

  group('pull to refresh (B7)', () {
    setUp(() async {
      h.page(1, posts(1, 3));
      await h.cubit.load();
    });

    test('the posts stay until the new first page lands', () async {
      final answer = Completer<Either<Failure, CommunityPage<CommunityPost>>>();
      when(() => h.getFeed(page: 1)).thenAnswer((_) => answer.future);

      final refreshing = h.cubit.refresh();
      expect(h.cubit.state.refreshing, isTrue);
      expect(_ids(h), [1, 2, 3]);

      answer.complete(
        const Right(
          CommunityPage(
            items: [],
            pageNumber: 1,
            pageSize: 20,
            totalCount: 0,
            totalPages: 0,
          ),
        ),
      );
      await refreshing;
      expect(h.cubit.state.status, CommunityFeedStatus.empty);
    });

    test('offline, the posts already here stay (B6)', () async {
      h.pageFails(1);

      await h.cubit.refresh();

      expect(h.cubit.state.status, CommunityFeedStatus.loaded);
      expect(_ids(h), [1, 2, 3]);
      expect(h.cubit.state.refreshing, isFalse);
    });
  });
}
