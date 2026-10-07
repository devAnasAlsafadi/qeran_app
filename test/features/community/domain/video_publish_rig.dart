import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/media_upload_outcome.dart';
import 'package:qeran/features/community/domain/entities/picked_video.dart';
import 'package:qeran/features/community/domain/entities/video_upload_grant.dart';
import 'package:qeran/features/community/domain/repositories/community_author_repository.dart';

import 'fake_video_compressor.dart';

/// 6.8's grant for [mediaId], running out at [expiresAt].
VideoUploadGrant videoGrant(String mediaId, {DateTime? expiresAt}) =>
    VideoUploadGrant(
      mediaId: mediaId,
      endpoint: Uri.parse('https://video.bunnycdn.com/tusupload'),
      expiresAt: expiresAt,
    );

/// Her picked video at [path]: a 30 s vertical MOV of 10 MB.
PickedVideo pickedVideo(String path) =>
    PickedVideo(path: path, container: VideoContainer.quickTime, info: clip());

/// 6.8 and tus over scripted answers. Grants are `v-1`, `v-2`… unless
/// [grant] says otherwise; tus makes `https://tus/<mediaId>` when it isn't
/// resuming, and reports half, then all, of the file ([hold] in between).
class VideoScript {
  VideoScript(this._repository) {
    grants();
    tus();
  }

  final CommunityAuthorRepository _repository;
  int _grants = 0;

  /// The length each 6.8 asked at, and the file it was for.
  final durations = <int>[];
  final grantedFiles = <String>[];

  /// Each tus upload's grant and the URL it resumed at (null: a new one).
  final sentUnder = <String>[];
  final resumedAt = <Uri?>[];

  VideoUploadGrant Function(String mediaId) grant = videoGrant;

  /// While set, tus stops at half until it completes.
  Completer<void>? hold;

  void grants([
    Either<Failure, MediaUploadOutcome<VideoUploadGrant>>? answer,
  ]) =>
      when(
        () => _repository.requestVideoUpload(
          any(),
          durationSeconds: any(named: 'durationSeconds'),
        ),
      ).thenAnswer((call) async {
        durations.add(call.namedArguments[#durationSeconds] as int);
        grantedFiles.add((call.positionalArguments.first as PickedVideo).path);
        return answer ?? Right(MediaUploaded(grant('v-${++_grants}')));
      });

  void tus([Either<Failure, Unit>? answer]) =>
      when(
        () => _repository.uploadVideo(
          any(),
          any(),
          resumeAt: any(named: 'resumeAt'),
          onCreated: any(named: 'onCreated'),
          onProgress: any(named: 'onProgress'),
          cancel: any(named: 'cancel'),
        ),
      ).thenAnswer((call) async {
        final grant = call.positionalArguments.first as VideoUploadGrant;
        final resumeAt = call.namedArguments[#resumeAt] as Uri?;
        sentUnder.add(grant.mediaId);
        resumedAt.add(resumeAt);
        if (resumeAt == null) {
          final created =
              call.namedArguments[#onCreated] as void Function(Uri)?;
          created?.call(Uri.parse('https://tus/${grant.mediaId}'));
        }
        final progress = call.namedArguments[#onProgress] as UploadProgress?;
        progress?.call(50, 100);
        if (hold case final hold?) await hold.future;
        progress?.call(100, 100);
        return answer ?? const Right(unit);
      });
}
