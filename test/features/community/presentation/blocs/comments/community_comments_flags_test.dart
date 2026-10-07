import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/community_flag.dart';
import 'package:qeran/features/community/presentation/blocs/comments/community_comments_state.dart';

import '../../../fixtures/community_comment_fixtures.dart';
import 'comments_cubit_harness.dart';

const _flag = CommunityFlag(id: 77, reportCount: 2);
const _replyFlag = CommunityFlag(id: 78, reportCount: 1);

/// Her answers to a report on her post (E1–E6, S16).
void main() {
  late CommentsHarness h;
  final flagged = testComment(id: 10, replyCount: 1, flag: _flag);
  final reply = testReply(id: 100, parentId: 10, flag: _replyFlag);

  setUp(() async {
    h = CommentsHarness()..page(1, [flagged, testComment(id: 9)]);
    h.replies(10, 1, [reply]);
    await h.cubit.load();
    await h.cubit.showReplies(10);
  });
  tearDown(() => h.cubit.close());

  CommunityCommentsState get() => h.cubit.state;

  test('Keep: dismisses that flag, and the flag leaves the row in place; '
      '«أُبقي التعليق…»; her badges read again (E3, S16)', () async {
    when(() => h.dismissFlag(77)).thenAnswer((_) async => const Right(unit));

    await h.cubit.keep(flagged);

    expect(get().threads.first.comment.flag, isNull);
    expect(get().threads.first.comment.text, flagged.text);
    expect(get().threads.first.replies.single.flag, _replyFlag);
    expect(get().event, CommunityCommentsEvent.kept);
    expect(h.flagsCleared, 1);
  });

  test('a reply kept: its own toast (Q11)', () async {
    when(() => h.dismissFlag(78)).thenAnswer((_) async => const Right(unit));

    await h.cubit.keep(reply);

    expect(get().threads.first.replies.single.flag, isNull);
    expect(get().event, CommunityCommentsEvent.keptReply);
  });

  test('Keep fails: the flag stays, and the screen says so', () async {
    when(
      () => h.dismissFlag(77),
    ).thenAnswer((_) async => const Left(OfflineFailure()));

    await h.cubit.keep(flagged);

    expect(get().threads.first.comment.flag, _flag);
    expect(get().event, CommunityCommentsEvent.keepFailed);
    expect(h.flagsCleared, 0);
  });

  test('a second tap while it keeps sends nothing more', () async {
    when(() => h.dismissFlag(77)).thenAnswer((_) async => const Right(unit));

    await Future.wait([h.cubit.keep(flagged), h.cubit.keep(flagged)]);

    verify(() => h.dismissFlag(77)).called(1);
  });

  test('deleting a reported item reads her badges again (E6, S16); an '
      'unreported one doesn\'t need to', () async {
    when(() => h.delete(any())).thenAnswer((_) async => const Right(unit));

    await h.cubit.delete(get().threads.last.comment);
    expect(h.flagsCleared, 0);
    await h.cubit.delete(flagged);

    expect(h.flagsCleared, 1);
    expect(get().event, CommunityCommentsEvent.deleted);
  });
}
