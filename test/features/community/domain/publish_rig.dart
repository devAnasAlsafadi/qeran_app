import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/media_upload_outcome.dart';
import 'package:qeran/features/community/domain/entities/picked_image.dart';
import 'package:qeran/features/community/domain/entities/post_publish_outcome.dart';
import 'package:qeran/features/community/domain/entities/publish_event.dart';
import 'package:qeran/features/community/domain/entities/publish_session.dart';
import 'package:qeran/features/community/domain/repositories/community_author_repository.dart';

class MockAuthorRepository extends Mock implements CommunityAuthorRepository {}

/// A picked JPEG at [path] of [size] bytes.
PickedImage pickedImage(String path, {int size = 100}) => PickedImage(
  file: UploadFile(
    path: path,
    fileName: 'image.jpg',
    contentType: 'image/jpeg',
  ),
  format: ImageFormat.jpeg,
  sizeBytes: size,
);

/// The author repository over scripted answers. Uploads report half, then
/// all, of their bytes; [sent] keeps each upload's path in order, and
/// [requestIds] each 6.2's id. Request ids are `req-1`, `req-2`…
class PublishRig {
  PublishRig() {
    registerFallbackValue(pickedImage('fallback').file);
    when(
      () => repository.deleteMedia(any()),
    ).thenAnswer((_) async => const Right(unit));
    creates(const Left(OfflineFailure()));
  }

  final repository = MockAuthorRepository();
  final sent = <String>[];
  final requestIds = <String>[];
  final cancels = <UploadCancel?>[];
  int _ids = 0;
  late final session = PublishSession(newRequestId: () => 'req-${++_ids}');

  /// The image at [path] answers [answer] (by default its id `id-<path>`).
  void uploads(
    String path, [
    Either<Failure, MediaUploadOutcome<String>>? answer,
  ]) =>
      when(
        () => repository.uploadImage(
          any(that: _atPath(path)),
          onProgress: any(named: 'onProgress'),
          cancel: any(named: 'cancel'),
        ),
      ).thenAnswer((call) async {
        sent.add(path);
        cancels.add(call.namedArguments[#cancel] as UploadCancel?);
        final progress = call.namedArguments[#onProgress] as UploadProgress?;
        progress?.call(50, 100);
        progress?.call(100, 100);
        return answer ?? Right(MediaUploaded('id-$path'));
      });

  void creates(Either<Failure, PostPublishOutcome> answer) =>
      when(
        () => repository.createPost(
          text: any(named: 'text'),
          clientRequestId: any(named: 'clientRequestId'),
          imageMediaIds: any(named: 'imageMediaIds'),
        ),
      ).thenAnswer((call) async {
        requestIds.add(call.namedArguments[#clientRequestId] as String);
        return answer;
      });

  /// The ids the last 6.2 carried.
  List<String> lastImageIds() =>
      verify(
            () => repository.createPost(
              text: any(named: 'text'),
              clientRequestId: any(named: 'clientRequestId'),
              imageMediaIds: captureAny(named: 'imageMediaIds'),
            ),
          ).captured.last
          as List<String>;
}

Matcher _atPath(String path) =>
    isA<UploadFile>().having((f) => f.path, 'path', path);

/// The events' kinds and progress, compactly: `up 50`, `creating`, …
List<String> describe(List<PublishEvent> events) => [
  for (final e in events)
    switch (e) {
      PublishUploading(:final progress) => 'up ${(progress * 100).round()}',
      PublishCreating() => 'creating',
      PublishAnswered(:final outcome) => 'answered ${outcome.runtimeType}',
      PublishImageRefused(:final path) => 'refused $path',
      PublishFailed() => 'failed',
      PublishCancelled() => 'cancelled',
    },
];
