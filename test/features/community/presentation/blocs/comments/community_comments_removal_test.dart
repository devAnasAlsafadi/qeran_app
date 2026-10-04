import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/presentation/blocs/comments/community_comments_state.dart';

import '../../../fixtures/community_comment_fixtures.dart';
import 'comments_cubit_harness.dart';

/// Deleting the member's own comment or reply (E8–E10, D16), and a blocked
/// member's rows leaving (E12) — each followed by a fresh read of the
/// post's counts (S4).
void main() {
  late CommentsHarness h;

  final mine = testComment(id: 11, author: sara, isMine: true, canDelete: true);
  final myReply = testReply(id: 100, author: sara);

  setUp(() async {
    h = CommentsHarness();
    h.page(1, [testComment(id: 10, author: fahad, replyCount: 1), mine]);
    h.replies(10, 1, [myReply]);
    await h.cubit.load();
    await h.cubit.showReplies(10);
    clearInteractions(h.getPost);
  });
  tearDown(() => h.dispose());

  List<int> ids() => [for (final t in h.cubit.state.threads) t.id];

  test(
    'a comment: gone with its replies, said once, counts read again',
    () async {
      when(() => h.delete(11)).thenAnswer((_) async => const Right(unit));

      await h.cubit.delete(mine);

      expect(ids(), [10]);
      expect(h.cubit.state.event, CommunityCommentsEvent.deleted);
      verify(() => h.getPost(1)).called(1);
    },
  );

  test('a reply: gone, its own words, one fewer on its comment', () async {
    when(() => h.delete(100)).thenAnswer((_) async => const Right(unit));

    await h.cubit.delete(myReply);

    final thread = h.cubit.state.threads.first;
    expect(thread.replies, isEmpty);
    expect(thread.comment.replyCount, 0);
    expect(h.cubit.state.event, CommunityCommentsEvent.deletedReply);
  });

  test('a failure: the row stays, and the screen says so', () async {
    when(
      () => h.delete(11),
    ).thenAnswer((_) async => const Left(OfflineFailure()));

    await h.cubit.delete(mine);

    expect(ids(), [10, 11]);
    expect(h.cubit.state.event, CommunityCommentsEvent.deleteFailed);
    verifyNever(() => h.getPost(1));
  });

  test('a second tap while deleting sends nothing more', () async {
    final pending = Completer<Either<Failure, Unit>>();
    when(() => h.delete(11)).thenAnswer((_) => pending.future);

    final first = h.cubit.delete(mine);
    await h.cubit.delete(mine);
    pending.complete(const Right(unit));
    await first;

    verify(() => h.delete(11)).called(1);
  });

  test('a blocked member: their rows go, the screen stays, counts read '
      'again (E12)', () async {
    h.cubit.removeAuthor(fahad.id);

    expect(ids(), [11]);
    expect(h.cubit.state.status, CommunityCommentsStatus.loaded);
    verify(() => h.getPost(1)).called(1);
  });

  test('the last comment gone: the empty state', () async {
    h.cubit.removeAuthor(fahad.id);
    when(() => h.delete(11)).thenAnswer((_) async => const Right(unit));

    await h.cubit.delete(mine);

    expect(h.cubit.state.status, CommunityCommentsStatus.empty);
  });
}
