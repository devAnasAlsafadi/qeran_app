import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/domain/entities/community_post_change.dart';

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
}
