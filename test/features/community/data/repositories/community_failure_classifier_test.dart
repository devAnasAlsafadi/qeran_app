import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/data/repositories/community_failure_classifier.dart';
import 'package:qeran/features/community/domain/entities/comment_submit_outcome.dart';
import 'package:qeran/generated/locale_keys.g.dart';

CodedServerFailure coded(String? code, {int? status}) =>
    CodedServerFailure(message: 'm', errorCode: code, statusCode: status);

void main() {
  group('classifyCommentFailure', () {
    final cases = <String, Type>{
      'CONTENT_NOT_ALLOWED': CommentFiltered,
      'DISPLAY_NAME_REQUIRED': CommentNameRequired,
      'COMMUNITY_GUIDELINES_NOT_ACCEPTED': CommentGuidelinesRequired,
      'PROFILE_NOT_APPROVED': CommentNotApproved,
      'POST_NOT_FOUND': CommentPostGone,
      'RATE_LIMITED': CommentRateLimited,
    };
    for (final MapEntry(key: code, value: type) in cases.entries) {
      test('$code → $type', () {
        expect(
          classifyCommentFailure(coded(code), isReply: false).runtimeType,
          type,
        );
      });
    }

    test('COMMENT_NOT_FOUND is the parent gone — on a reply only', () {
      expect(classifyCommentFailure(coded('COMMENT_NOT_FOUND'), isReply: true),
          isA<CommentParentGone>());
      expect(classifyCommentFailure(coded('COMMENT_NOT_FOUND'), isReply: false),
          isNull);
    });

    test('a bare 429 is rate limited, by status or by message', () {
      expect(classifyCommentFailure(coded(null, status: 429), isReply: false),
          isA<CommentRateLimited>());
      expect(
        classifyCommentFailure(
          const ServerFailure(message: LocaleKeys.errors_too_many_requests),
          isReply: true,
        ),
        isA<CommentRateLimited>(),
      );
    });

    test('no wait time is known yet (the consumer drops `data`)', () {
      final outcome = classifyCommentFailure(coded('RATE_LIMITED'),
          isReply: false) as CommentRateLimited;

      expect(outcome.retryAfter, isNull);
    });

    test('everything else stays a failure', () {
      expect(classifyCommentFailure(coded('VALIDATION_ERROR'), isReply: false),
          isNull);
      expect(classifyCommentFailure(const OfflineFailure(), isReply: false),
          isNull);
      expect(
        classifyCommentFailure(const ServerFailure(message: 'x'), isReply: false),
        isNull,
      );
    });
  });

  test('communityErrorCode reads only coded failures', () {
    expect(communityErrorCode(coded('POST_NOT_FOUND')), 'POST_NOT_FOUND');
    expect(communityErrorCode(const OfflineFailure()), isNull);
  });
}
