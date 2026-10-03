import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/features/community/presentation/blocs/comments/community_comments_state.dart';

import '../../../fixtures/community_comment_fixtures.dart';
import 'comments_cubit_harness.dart';

void main() {
  late CommentsHarness h;
  setUp(() => h = CommentsHarness());
  tearDown(() => h.dispose());

  group('pull to refresh', () {
    setUp(() async {
      h.page(1, comments(1, 3));
      await h.cubit.load();
    });

    test('the comments stay until the first page lands', () async {
      final answer = Completer<CommentsAnswer>();
      when(() => h.getComments(1, page: 1)).thenAnswer((_) => answer.future);

      final refreshing = h.cubit.refresh();
      expect(h.cubit.state.refreshing, isTrue);
      expect(h.ids, [1, 2, 3]);

      answer.complete(Right(commentPage(comments(0, 3))));
      await refreshing;
      expect(h.ids, [0, 1, 2, 3]);
      expect(h.cubit.state.refreshing, isFalse);
    });

    test('offline: the comments stay, and no error', () async {
      h.pageFails(1);

      await h.cubit.refresh();

      expect(h.cubit.state.status, CommunityCommentsStatus.loaded);
      expect(h.ids, [1, 2, 3]);
      expect(h.cubit.state.refreshing, isFalse);
    });

    test('after the first page failed, a pull loads it', () async {
      h.pageFails(1);
      await h.cubit.load();

      h.page(1, comments(1, 2));
      await h.cubit.refresh();

      expect(h.cubit.state.status, CommunityCommentsStatus.loaded);
    });
  });
}
