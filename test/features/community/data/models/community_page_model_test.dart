import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/data/models/community_comment_model.dart';
import 'package:qeran/features/community/data/models/community_page_model.dart';
import 'package:qeran/features/community/data/models/community_post_model.dart';

import '../../fixtures/community_fixtures.dart';

void main() {
  group('CommunityPageModel', () {
    test('a feed page keeps the server order and reports more pages', () {
      final page = CommunityPageModel.fromJson(
        paged([post(id: 3), post(id: 2)]),
        CommunityPostModel.fromJson,
      ).toEntity((m) => m.toEntity());

      expect(page.items.map((p) => p.id), [3, 2]);
      expect(page.pageNumber, 1);
      expect(page.pageSize, 20);
      expect(page.totalCount, 26);
      expect(page.totalPages, 2);
      expect(page.hasMore, isTrue);
    });

    test('the last page has no more', () {
      final page = CommunityPageModel.fromJson(
        paged([comment()], pageNumber: 2, totalPages: 2),
        CommunityCommentModel.fromJson,
      ).toEntity((m) => m.toEntity());

      expect(page.hasMore, isFalse);
    });

    test('entries that are not objects are dropped', () {
      final page = CommunityPageModel.fromJson(
        {
          ...paged(const []),
          'data': [comment(), null, 'x', 42],
        },
        CommunityCommentModel.fromJson,
      ).toEntity((m) => m.toEntity());

      expect(page.items, hasLength(1));
    });

    test('an empty body gives an empty first page with no more', () {
      final page = CommunityPageModel.fromJson(
        const {},
        CommunityPostModel.fromJson,
      ).toEntity((m) => m.toEntity());

      expect(page.items, isEmpty);
      expect(page.pageNumber, 1);
      expect(page.hasMore, isFalse);
    });
  });
}
