import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/progress_uploader.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/community/data/datasources/community_author_refusing_datasource.dart';
import 'package:qeran/features/community/data/datasources/community_author_remote_datasource_impl.dart';
import 'package:qeran/features/report/domain/entities/report_reason.dart';

import '../../fixtures/community_fixtures.dart';

class _MockApiConsumer extends Mock implements ApiConsumer {}

class _MockUploader extends Mock implements ProgressUploader {}

Map<String, dynamic> _ok(Object? data) => {
  'status': 1,
  'message': '',
  'errorCode': null,
  'data': data,
};

/// A row of `GET community/my-posts/flags` (contract §5.3).
Map<String, dynamic> flaggedRow() => {
  'flag': {
    'id': 77,
    'reportCount': 2,
    'reasons': [
      {'reason': 'Spam', 'count': 2},
    ],
    'lastReportedAt': '2026-10-02T09:15:00Z',
  },
  'comment': comment(),
  'post': {'id': 123, 'textSnippet': 'الاستخارة والاستشارة'},
};

void main() {
  late _MockApiConsumer api;
  late CommunityAuthorRemoteDataSourceImpl ds;

  setUp(() {
    api = _MockApiConsumer();
    ds = CommunityAuthorRemoteDataSourceImpl(
      apiConsumer: api,
      uploader: _MockUploader(),
    );
  });

  void answerGet(Object? data) => when(
    () => api.get(any(), queryParameters: any(named: 'queryParameters')),
  ).thenAnswer((_) async => _ok(data));

  test('her posts: GET community/my-posts, paged, every status', () async {
    answerGet(
      paged([
        post(id: 9, status: 'Processing'),
        post(id: 8, status: 'Failed'),
        post(id: 7),
      ]),
    );

    final page = await ds.getMyPosts(page: 2, pageSize: 20);

    verify(
      () => api.get(
        'community/my-posts',
        queryParameters: {'page': 2, 'pageSize': 20},
      ),
    ).called(1);
    expect(page.items.map((p) => p.id), [9, 8, 7]);
    expect(page.totalCount, 26);
  });

  test('publish: POST community/posts with the text and the request id; '
      'the post comes back', () async {
    when(
      () => api.post(any(), body: any(named: 'body')),
    ).thenAnswer((_) async => _ok(post(id: 31)));

    final made = await ds.createPost(text: 'إرشاد', clientRequestId: 'req-1');

    verify(
      () => api.post(
        'community/posts',
        body: {'text': 'إرشاد', 'clientRequestId': 'req-1'},
      ),
    ).called(1);
    expect(made.id, 31);
  });

  test('delete: DELETE community/posts/{id}', () async {
    when(() => api.delete(any())).thenAnswer((_) async => _ok(null));

    await ds.deletePost(123);

    verify(() => api.delete('community/posts/123')).called(1);
  });

  test('flags: GET community/my-posts/flags, paged; a row reads the flag, '
      'the comment and the post\'s id and snippet', () async {
    answerGet(paged([flaggedRow()]));

    final page = await ds.getFlags(page: 1, pageSize: 20);

    verify(
      () => api.get(
        'community/my-posts/flags',
        queryParameters: {'page': 1, 'pageSize': 20},
      ),
    ).called(1);
    final row = page.items.single.toEntity()!;
    expect(row.flag.id, 77);
    expect(row.flag.topReason, ReportReason.spam);
    expect(row.comment.id, 456);
    expect(row.postId, 123);
    expect(row.postSnippet, 'الاستخارة والاستشارة');
  });

  test('dismiss: POST community/flags/{id}/dismiss, no body', () async {
    when(() => api.post(any())).thenAnswer((_) async => _ok(null));

    await ds.dismissFlag(77);

    verify(() => api.post('community/flags/77/dismiss')).called(1);
  });

  test("the server's code passes through for the repository", () async {
    when(
      () => api.delete(any()),
    ).thenThrow(CodedServerException(message: 'x', errorCode: 'UNAUTHORIZED'));

    expect(
      () => ds.deletePost(5),
      throwsA(
        isA<CodedServerException>().having(
          (e) => e.errorCode,
          'errorCode',
          'UNAUTHORIZED',
        ),
      ),
    );
  });

  test('a success with no page in it is a server fault', () {
    answerGet(null);

    expect(
      () => ds.getMyPosts(page: 1, pageSize: 20),
      throwsA(isA<ServerException>()),
    );
  });

  test('the dev-flag build refuses every author call, so a mock id never '
      'reaches the live server', () {
    const refusing = CommunityAuthorRefusingDataSource();

    expect(() => refusing.deletePost(1), throwsA(isA<ServerException>()));
    expect(
      () => refusing.getMyPosts(page: 1, pageSize: 20),
      throwsA(isA<ServerException>()),
    );
    expect(() => refusing.dismissFlag(1), throwsA(isA<ServerException>()));
  });
}
