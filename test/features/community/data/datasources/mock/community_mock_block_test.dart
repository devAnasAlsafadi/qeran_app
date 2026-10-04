import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/data/datasources/mock/community_mock_datasource.dart';
import 'package:qeran/features/community/data/models/community_comment_model.dart';

import '../../../fixtures/community_mock_harness.dart';

/// The mock's block (D6, D23): in memory (Q3), and what was blocked is gone
/// for the viewer — rows, replies, counts — as the server does.
void main() {
  late CommunityMockDataSource ds;
  late int postId;

  setUp(() async {
    ds = seededMock();
    postId = (await ds.getFeed(page: 1, pageSize: 20)).items.first.id;
  });

  Future<List<CommunityCommentModel>> comments() async => [
    for (final page in [1, 2])
      ...(await ds.getComments(postId, page: page, pageSize: 20)).items,
  ];

  test(
    "a member's comments and replies go, and the counts with them",
    () async {
      final sara = (await comments()).first;
      final before = (await ds.getPost(postId)).commentCount;
      final saraWrote = (await comments())
          .where((c) => c.author.id == sara.author.id)
          .length;

      await ds.blockMember(sara.author.id);

      expect(
        (await comments()).where((c) => c.author.id == sara.author.id),
        isEmpty,
      );
      // Her comments, and every reply under them (3 under the first).
      expect(
        (await ds.getPost(postId)).commentCount,
        lessThanOrEqualTo(before - saraWrote - 3),
      );
      await expectLater(
        ds.getComment(sara.id),
        throwsCoded('COMMENT_NOT_FOUND'),
      );
    },
  );

  test('a matchmaker cannot be blocked (D18)', () async {
    await expectLater(
      ds.blockMember('mock-mm-huda'),
      throwsCoded('BLOCK_NOT_ALLOWED'),
    );
  });

  test('an unknown member is the neutral not-found', () async {
    await expectLater(
      ds.blockMember('nobody'),
      throwsCoded('TARGET_USER_NOT_FOUND'),
    );
  });
}
