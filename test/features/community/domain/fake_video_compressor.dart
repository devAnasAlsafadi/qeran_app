import 'dart:async';

import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/community/domain/ports/video_compressor.dart';

/// The phone's compressor over scripted answers.
///
/// Inspecting: a vertical 30 s clip of 10 MB unless [infos] says otherwise
/// (null: it can't be read). Compressing: reports half, then all, and
/// answers [answer] — by default `<path>.mp4`, the same clip at 4 MB; null
/// is "not available" (Q2). While [hold] is set it runs until that
/// completes; her cancel then throws, as the adapter does.
class FakeCompressor implements VideoCompressor {
  final infos = <String, VideoFileInfo?>{};

  /// Each compression's source, in order.
  final compressed = <String>[];
  CompressedVideo? Function(String path) answer = (path) => CompressedVideo(
    path: '$path.mp4',
    info: clip(bytes: 4 * _mb),
  );
  Completer<void>? hold;
  int deletions = 0;

  @override
  Future<VideoFileInfo?> inspect(String path) async =>
      infos.containsKey(path) ? infos[path] : clip();

  @override
  Future<CompressedVideo?> compress(
    String path, {
    void Function(double progress)? onProgress,
    UploadCancel? cancel,
  }) async {
    compressed.add(path);
    onProgress?.call(0.5);
    if (hold case final hold?) {
      await Future.any([hold.future, ?cancel?.whenCancelled]);
    }
    if (cancel?.isCancelled ?? false) throw const UploadCancelledException();
    onProgress?.call(1);
    return answer(path);
  }

  @override
  Future<void> deleteCopies() async => deletions++;
}

const _mb = 1024 * 1024;

/// A clip's facts: [seconds] long, [width] × [height], [bytes] big.
VideoFileInfo clip({
  double seconds = 30,
  int width = 1080,
  int height = 1920,
  int bytes = 10 * _mb,
}) => VideoFileInfo(
  duration: Duration(milliseconds: (seconds * 1000).round()),
  width: width,
  height: height,
  sizeBytes: bytes,
);
