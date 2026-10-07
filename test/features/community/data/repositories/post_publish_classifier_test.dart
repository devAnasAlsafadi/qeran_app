import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/data/models/community_post_model.dart';
import 'package:qeran/features/community/data/repositories/post_publish_classifier.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/domain/entities/media_refusal.dart';
import 'package:qeran/features/community/domain/entities/media_upload_outcome.dart';
import 'package:qeran/features/community/domain/entities/post_publish_outcome.dart';

import '../../fixtures/community_fixtures.dart';

Failure _coded(String code, {int? status}) =>
    CodedServerFailure(message: 'x', errorCode: code, statusCode: status);

/// Plan §3.4's "Answers → states", row by row.
void main() {
  group('the post (6.2)', () {
    Either<Failure, PostPublishOutcome> answer(Failure failure) =>
        postPublishOutcomeOf(Left(failure));

    test('a post, Published or Processing: made (D5, D4)', () {
      for (final status in ['Published', 'Processing']) {
        final made = CommunityPostModel.fromJson(
          post(id: 31, status: status),
        ).toEntity();
        final outcome = postPublishOutcomeOf(
          Right<Failure, CommunityPost>(made),
        );
        expect(
          outcome.fold((_) => null, (o) => (o as PostPublished).post.id),
          31,
        );
      }
    });

    final stops = <String, Matcher>{
      'CONTENT_NOT_ALLOWED': isA<PostRejected>(),
      'COMMUNITY_GUIDELINES_NOT_ACCEPTED': isA<PostGuidelinesRequired>(),
      'VIDEO_SERVICE_UNAVAILABLE': isA<PostVideoUnavailable>(),
      'VALIDATION_ERROR': isA<PostTextInvalid>(),
      for (final lost in [
        'MEDIA_UPLOAD_FAILED',
        'MEDIA_PROCESSING_FAILED',
        'MEDIA_NOT_FOUND',
        'MEDIA_NOT_READY',
      ])
        lost: isA<PostMediaLost>(),
      for (final (code, refusal) in [
        ('MEDIA_TOO_LONG', MediaRefusal.tooLong),
        ('MEDIA_TOO_LARGE', MediaRefusal.tooLarge),
        ('MEDIA_INVALID_TYPE', MediaRefusal.invalidType),
      ])
        code: isA<PostMediaRefused>().having(
          (o) => o.refusal,
          'refusal',
          refusal,
        ),
    };
    for (final MapEntry(key: code, value: matcher) in stops.entries) {
      test('$code: an outcome she has a screen for', () {
        expect(answer(_coded(code)).fold((f) => f, (o) => o), matcher);
      });
    }

    test('MEDIA_LIMIT_REACHED, offline, a timeout, a 429 or an unknown '
        'code: the failed strip (D3, S7)', () {
      for (final failure in [
        _coded('MEDIA_LIMIT_REACHED'),
        const OfflineFailure(),
        const ServerFailure(message: 'timeout'),
        _coded('RATE_LIMITED', status: 429),
        _coded('SOMETHING_NEW'),
      ]) {
        expect(answer(failure), Left<Failure, PostPublishOutcome>(failure));
      }
    });
  });

  group('one upload (6.7, 6.8)', () {
    Object? answer(Failure failure) =>
        mediaUploadOutcomeOf<String>(Left(failure)).fold((f) => f, (o) => o);

    test('uploaded: the value for the next step', () {
      final outcome = mediaUploadOutcomeOf<String>(const Right('m-1'));
      expect(
        outcome.fold((_) => null, (o) => (o as MediaUploaded<String>).value),
        'm-1',
      );
    });

    test('the server\'s own checks: refusals', () {
      expect(
        answer(_coded('MEDIA_TOO_LARGE')),
        isA<MediaUploadRefused<String>>().having(
          (o) => o.refusal,
          'refusal',
          MediaRefusal.tooLarge,
        ),
      );
      expect(
        answer(_coded('MEDIA_TOO_LONG')),
        isA<MediaUploadRefused<String>>().having(
          (o) => o.refusal,
          'refusal',
          MediaRefusal.tooLong,
        ),
      );
      expect(
        answer(_coded('MEDIA_INVALID_TYPE')),
        isA<MediaUploadRefused<String>>().having(
          (o) => o.refusal,
          'refusal',
          MediaRefusal.invalidType,
        ),
      );
    });

    test('the video service down: its own outcome (BA-A6)', () {
      expect(
        answer(_coded('VIDEO_SERVICE_UNAVAILABLE')),
        isA<MediaVideoUnavailable<String>>(),
      );
    });

    test('her cancel, MEDIA_LIMIT_REACHED, offline: failures', () {
      for (final failure in [
        const UploadCancelledFailure(),
        _coded('MEDIA_LIMIT_REACHED'),
        const OfflineFailure(),
      ]) {
        expect(answer(failure), failure);
      }
    });
  });
}
