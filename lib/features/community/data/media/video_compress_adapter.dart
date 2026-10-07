import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:video_compress/video_compress.dart';

import '../../domain/ports/video_compressor.dart';

/// [VideoCompressor] over `video_compress` 3.1.4 (plan §3.4). What the phone
/// answers was read from the package's Android and iOS code, and is still to
/// be seen on a device, a vertical and a landscape clip on each (V14).
///
/// The package holds one compression in global state and throws when a
/// second one starts, so compressions here run **one at a time**: a second
/// call waits until the phone has answered the first. The usual second call
/// is her retry right after a cancel, which answers her at once while the
/// phone takes a moment to stop.
///
/// Every failure that isn't her cancel answers null, and the caller uploads
/// the original (Q2). Android's plugin answers a failed compression with
/// null, the same answer as "not available", so the two can't be told apart
/// there, and a different answer on iOS would give one file two outcomes on
/// two phones.
class VideoCompressAdapter implements VideoCompressor {
  /// [platform] says whose numbers `getMediaInfo` answers with (see
  /// [_displaySize]): the running one, unless a test says otherwise.
  VideoCompressAdapter({TargetPlatform? platform})
    : _platform = platform ?? defaultTargetPlatform;

  final TargetPlatform _platform;

  /// The phone's last compression. The next one starts once it answered.
  static Future<void> _phone = Future.value();

  @override
  Future<VideoFileInfo?> inspect(String path) async {
    try {
      return await _factsOf(await VideoCompress.getMediaInfo(path), path);
    } catch (e) {
      // The package decodes an unreadable file's null answer with a null
      // check, so what comes here is an Error, not an Exception.
      AppLogger.warning('Video not readable: $e', tag: 'VIDEO');
      return null;
    }
  }

  @override
  Future<CompressedVideo?> compress(
    String path, {
    void Function(double progress)? onProgress,
    UploadCancel? cancel,
  }) async {
    final job = _phone.then((_) => _onThePhone(path, onProgress, cancel));
    _phone = job.then((_) {});
    final answer = await Future.any<MediaInfo?>([
      job,
      if (cancel != null) cancel.whenCancelled.then((_) => null),
    ]);
    if (cancel?.isCancelled ?? false) throw const UploadCancelledException();
    return _copyOf(answer);
  }

  /// The package's folder of copies, emptied after the phone's last
  /// compression: Android's external files `video_compress`, iOS's
  /// temporary `video_compress`. Each is made again by the next one.
  @override
  Future<void> deleteCopies() {
    final job = _phone.then((_) => _deleteAll());
    _phone = job;
    return job;
  }

  static Future<void> _deleteAll() async {
    try {
      await VideoCompress.deleteAllCache();
    } catch (e) {
      AppLogger.warning('Video copies not deleted: $e', tag: 'VIDEO');
    }
  }

  /// One compression, from its start to the phone's answer. It never
  /// throws: a failure is null. Her cancel stops the phone only while it
  /// works, because on iOS a cancel with nothing running marks the next
  /// compression cancelled.
  Future<MediaInfo?> _onThePhone(
    String path,
    void Function(double progress)? onProgress,
    UploadCancel? cancel,
  ) async {
    if (cancel?.isCancelled ?? false) return null;
    var running = true;
    Subscription? ticks;
    try {
      ticks = _listen(onProgress, cancel);
      cancel?.whenCancelled.then((_) {
        if (running) VideoCompress.cancelCompression().ignore();
      });
      return await VideoCompress.compressVideo(
        path,
        quality: VideoQuality.Res1280x720Quality,
        includeAudio: true,
        deleteOrigin: false,
      );
    } catch (e) {
      // A missing plugin throws here, and leaves the package "compressing"
      // for good: the calls after it fail too, and also answer null.
      AppLogger.warning('Video not compressed: $e', tag: 'VIDEO');
      return null;
    } finally {
      running = false;
      ticks?.unsubscribe();
    }
  }

  /// Her progress from the package's ticks (0–100), until she cancels. The
  /// package keeps ticks nobody listened to and hands them to the next
  /// listener, so a tick left over from the last compression is dropped
  /// first.
  Subscription _listen(
    void Function(double progress)? onProgress,
    UploadCancel? cancel,
  ) {
    VideoCompress.compressProgress$.subscribe((_) {}).unsubscribe();
    return VideoCompress.compressProgress$.subscribe((percent) {
      if (cancel?.isCancelled ?? false) return;
      onProgress?.call((percent / 100).clamp(0.0, 1.0));
    });
  }

  /// The copy the phone wrote, or null when it wrote none. iOS answers a
  /// cancel she didn't send (one that reached it just as the last
  /// compression ended) with the original's facts and `isCancel`.
  Future<CompressedVideo?> _copyOf(MediaInfo? answer) async {
    final path = answer?.path;
    if (answer == null || path == null || answer.isCancel == true) {
      return null;
    }
    try {
      final facts = await _factsOf(answer, path);
      return facts == null ? null : CompressedVideo(path: path, info: facts);
    } on FileSystemException {
      return null;
    }
  }

  /// The facts in [info], or null when one is missing. The size is read
  /// from the file itself, because iOS's `filesize` counts the video
  /// track's samples only, without the audio and the container.
  Future<VideoFileInfo?> _factsOf(MediaInfo info, String path) async {
    final (ms, width, height) = (info.duration, info.width, info.height);
    if (ms == null || width == null || height == null) return null;
    final (w, h) = _displaySize(width, height, info.orientation);
    return VideoFileInfo(
      duration: Duration(milliseconds: ms.round()),
      width: w,
      height: h,
      sizeBytes: await File(path).length(),
    );
  }

  /// Width and height as she sees the video (plan §3.3). iOS answers them
  /// that way already: it applies the track's transform, and its
  /// `orientation` is a guess a quarter turn off (a plain landscape clip
  /// says 90). Android reads the stored size, then swaps it for 0° and 180°
  /// where 90° and 270° were meant, so whenever it read a rotation, its two
  /// numbers are the wrong way round.
  (int, int) _displaySize(int width, int height, int? orientation) =>
      _platform == TargetPlatform.android && orientation != null
      ? (height, width)
      : (width, height);
}
