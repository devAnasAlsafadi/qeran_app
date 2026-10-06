import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/domain/entities/community_post_change.dart';
import 'package:qeran/features/matchmaker/shared/domain/entities/community_post_status_change.dart';

import '../../../community/fixtures/community_post_fixtures.dart';
import '../community_screen_rig.dart';

List<int> _ids(CommunityScreenHarness h) => [
  for (final post in h.mine.state.posts) post.id,
];

void main() {
  late CommunityScreenHarness h;
  setUp(() => h = CommunityScreenHarness());
  tearDown(() => h.dispose());

  test('her posts in every status, newest first, each once (6.1)', () async {
    h.myPage(1, [
      testPost(id: 9, status: CommunityPostStatus.processing),
      testPost(id: 8, status: CommunityPostStatus.failed),
      testPost(id: 8, status: CommunityPostStatus.failed),
      testPost(id: 7),
    ]);

    await h.mine.load();

    expect(_ids(h), [9, 8, 7]);
  });

  test('a post she publishes joins at the top, still processing or not '
      '(D4, D5)', () async {
    h.myPage(1, [testPost(id: 7)]);
    await h.mine.load();

    h.all.changes.add(
      CommunityPostCreated(
        testPost(id: 9, status: CommunityPostStatus.processing),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(_ids(h), [9, 7]);
  });

  test('a post gone leaves her list too', () async {
    h.myPage(1, [testPost(id: 8), testPost(id: 7)]);
    await h.mine.load();

    h.all.changes.add(const CommunityPostGone(8));
    await Future<void>.delayed(Duration.zero);

    expect(_ids(h), [7]);
  });

  test('opening it, and each pull to refresh, clears her new comments '
      '(D33, S20)', () async {
    h.myPage(1, [testPost(id: 7)]);
    await h.mine.load();

    await h.mine.seen();
    await h.mine.refresh();

    expect(h.seen, 2);
  });

  group('the processing watch (plan §3.5, Q6)', () {
    final processing = testPost(id: 9, status: CommunityPostStatus.processing);
    final published = testPost(id: 9);

    /// Reading post 9 again answers [answer], and — as the repository does —
    /// hands it to every list.
    void rereadAnswers(CommunityPost answer) =>
        when(() => h.all.getPost(9)).thenAnswer((_) async {
          h.all.changes.add(CommunityPostUpdated(answer));
          return Right(answer);
        });

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('no processing post: no poll', () async {
      h.myPage(1, [testPost(id: 7)]);
      await h.mine.load();

      expect(h.ticks, isEmpty);
    });

    test('every tick reads it again; once published, the strip goes and '
        'the poll stops (S14)', () async {
      h.myPage(1, [processing, testPost(id: 7)]);
      await h.mine.load();
      rereadAnswers(processing);

      h.tick();
      await settle();
      verify(() => h.all.getPost(9)).called(1);
      expect(h.ticks, hasLength(1));

      rereadAnswers(published);
      h.tick();
      await settle();

      expect(h.mine.state.posts.first.status, CommunityPostStatus.published);
      expect(h.ticks, isEmpty);
    });

    test('the hub says it changed: read at once — only a post she has on '
        'her list', () async {
      h.myPage(1, [processing]);
      await h.mine.load();
      rereadAnswers(published);

      h.statusChanges.add(
        const CommunityPostStatusChange(
          postId: 9,
          status: CommunityPostStatus.published,
        ),
      );
      h.statusChanges.add(
        const CommunityPostStatusChange(
          postId: 3,
          status: CommunityPostStatus.published,
        ),
      );
      await settle();

      verify(() => h.all.getPost(9)).called(1);
      verifyNever(() => h.all.getPost(3));
      expect(h.mine.state.posts.first.status, CommunityPostStatus.published);
    });

    test('back in front, it is read at once; closed, the poll stops', () async {
      h.myPage(1, [processing]);
      await h.mine.load();
      rereadAnswers(processing);

      h.mine.checkProcessing();
      await settle();
      verify(() => h.all.getPost(9)).called(1);

      await h.mine.close();
      expect(h.ticks, isEmpty);
    });
  });
}
