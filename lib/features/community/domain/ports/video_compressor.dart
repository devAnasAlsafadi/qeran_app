import 'package:equatable/equatable.dart';
import 'package:qeran/core/domain/upload.dart';

/// What a picked video is, read from the file (plan §3.3): its length, its
/// display size after rotation (a vertical video has [width] < [height]),
/// and its size in bytes. The length is checked before compressing (BA-A9),
/// all four go into the upload grant (§3.4), and the preview takes its ratio
/// from here, never from the server (BA-D1).
class VideoFileInfo extends Equatable {
  final Duration duration;
  final int width;
  final int height;
  final int sizeBytes;

  const VideoFileInfo({
    required this.duration,
    required this.width,
    required this.height,
    required this.sizeBytes,
  });

  @override
  List<Object?> get props => [duration, width, height, sizeBytes];
}

/// The compressed copy to upload. It is always MP4 (plan §3.4).
class CompressedVideo extends Equatable {
  final String path;
  final VideoFileInfo info;

  const CompressedVideo({required this.path, required this.info});

  @override
  List<Object?> get props => [path, info];
}

/// The phone's video compressor (plan §3.4, D1). It sits behind a port so
/// that a compressor which builds on iOS can replace `video_compress` in
/// one adapter (Q2).
abstract class VideoCompressor {
  /// The file's facts, or null when they can't be read.
  Future<VideoFileInfo?> inspect(String path);

  /// An MP4 copy with the longest side 1280, which meets
  /// `videoTarget.maxHeight` (contract §8), with the audio kept.
  /// [onProgress] runs from 0 to 1. Throws `UploadCancelledException` once
  /// [cancel] fires.
  ///
  /// Answers null when compression isn't available on this device, or
  /// failed on this file: the caller then uploads the original, and only
  /// config's limits are checked (Q2).
  Future<CompressedVideo?> compress(
    String path, {
    void Function(double progress)? onProgress,
    UploadCancel? cancel,
  });

  /// Deletes every copy [compress] made, once a compression still running
  /// has ended. Best effort: it never throws.
  Future<void> deleteCopies();
}
