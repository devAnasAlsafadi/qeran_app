import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/community/data/datasources/community_remote_datasource_impl.dart';
import 'package:qeran/features/report/domain/entities/report_reason.dart';
import 'package:qeran/features/report/domain/entities/report_target.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../fixtures/community_fixtures.dart';

class _MockApiConsumer extends Mock implements ApiConsumer {}

Map<String, dynamic> ok(Object? data) =>
    {'status': 1, 'message': '', 'errorCode': null, 'data': data};

void main() {
  late _MockApiConsumer api;
  late CommunityRemoteDataSourceImpl ds;

  setUp(() {
    api = _MockApiConsumer();
    ds = CommunityRemoteDataSourceImpl(apiConsumer: api);
  });

  void answerGet(Object? data) => when(
        () => api.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer((_) async => ok(data));

  test('feed: GET community/posts with the page, data peeled from the envelope',
      () async {
    answerGet(paged([post(id: 9), post(id: 8)]));

    final page = await ds.getFeed(page: 2, pageSize: 20);

    verify(() => api.get('community/posts',
        queryParameters: {'page': 2, 'pageSize': 20})).called(1);
    expect(page.items.map((p) => p.id), [9, 8]);
  });

  test('post, comment, config and guidelines: one GET each', () async {
    answerGet(post());
    expect((await ds.getPost(123)).id, 123);
    verify(() => api.get('community/posts/123')).called(1);

    answerGet(comment());
    expect((await ds.getComment(456)).id, 456);
    verify(() => api.get('community/comments/456')).called(1);

    answerGet(config());
    expect((await ds.getConfig()).commentMaxLength, 500);
    verify(() => api.get('community/config')).called(1);

    answerGet(guidelines());
    expect((await ds.getGuidelines()).version, 3);
    verify(() => api.get('community/guidelines')).called(1);
  });

  test('comments and replies: their own paths, paged', () async {
    answerGet(paged([comment()]));

    await ds.getComments(123, page: 1, pageSize: 20);
    await ds.getReplies(456, page: 3, pageSize: 10);

    verify(() => api.get('community/posts/123/comments',
        queryParameters: {'page': 1, 'pageSize': 20})).called(1);
    verify(() => api.get('community/comments/456/replies',
        queryParameters: {'page': 3, 'pageSize': 10})).called(1);
  });

  test('like is PUT, unlike is DELETE, on posts and comments', () async {
    final answer = ok({'likeCount': 5, 'likedByMe': true});
    when(() => api.put(any())).thenAnswer((_) async => answer);
    when(() => api.delete(any())).thenAnswer((_) async => answer);

    expect((await ds.setPostLike(1, liked: true)).likeCount, 5);
    await ds.setPostLike(1, liked: false);
    await ds.setCommentLike(2, liked: true);
    await ds.setCommentLike(2, liked: false);

    verify(() => api.put('community/posts/1/like')).called(1);
    verify(() => api.delete('community/posts/1/like')).called(1);
    verify(() => api.put('community/comments/2/like')).called(1);
    verify(() => api.delete('community/comments/2/like')).called(1);
  });

  test('comment and reply send { text }; accept sends { version }', () async {
    when(() => api.post(any(), body: any(named: 'body')))
        .thenAnswer((_) async => ok(comment()));

    await ds.createComment(123, 'نص');
    await ds.createReply(456, 'رد');
    await ds.acceptGuidelines(3);

    verify(() => api.post('community/posts/123/comments', body: {'text': 'نص'}))
        .called(1);
    verify(() => api.post('community/comments/456/replies', body: {'text': 'رد'}))
        .called(1);
    verify(() => api.post('community/guidelines/accept', body: {'version': 3}))
        .called(1);
  });

  test('report: POST reports with the content type, the id as a string, '
      'and a trimmed note only when there is one (§5.1)', () async {
    when(() => api.post(any(), body: any(named: 'body')))
        .thenAnswer((_) async => ok('r-1'));

    await ds.reportContent(
      const ContentReportTarget(ReportContentKind.reply, 456),
      reason: ReportReason.contactDetails,
      note: '  رقم هاتف  ',
    );
    await ds.reportContent(
      const ContentReportTarget(ReportContentKind.post, 123),
      reason: ReportReason.spam,
      note: '   ',
    );

    verify(() => api.post('reports', body: {
          'targetContentType': 'Comment',
          'targetContentId': '456',
          'reason': 'ContactDetails',
          'note': 'رقم هاتف',
        })).called(1);
    verify(() => api.post('reports', body: {
          'targetContentType': 'Post',
          'targetContentId': '123',
          'reason': 'Spam',
        })).called(1);
  });

  test('block: the same POST block as a profile (D6)', () async {
    when(() => api.post(any(), body: any(named: 'body')))
        .thenAnswer((_) async => ok(null));

    await ds.blockMember('u-5');

    verify(() => api.post('block', body: {'targetUserId': 'u-5'})).called(1);
  });

  test('delete: DELETE community/comments/{id}', () async {
    when(() => api.delete(any())).thenAnswer((_) async => ok(null));

    await ds.deleteComment(456);

    verify(() => api.delete('community/comments/456')).called(1);
  });

  test('a success with no data object is an error, not an empty post', () async {
    answerGet(null);

    await expectLater(
      ds.getPost(1),
      throwsA(isA<ServerException>().having(
          (e) => e.message, 'message', LocaleKeys.errors_unexpected)),
    );
  });

  test("the consumer's coded errors pass through untouched", () async {
    when(() => api.post(any(), body: any(named: 'body'))).thenThrow(
      CodedServerException(message: 'm', errorCode: 'RATE_LIMITED'),
    );

    await expectLater(
      ds.createComment(1, 'x'),
      throwsA(isA<CodedServerException>()
          .having((e) => e.errorCode, 'errorCode', 'RATE_LIMITED')),
    );
  });
}
