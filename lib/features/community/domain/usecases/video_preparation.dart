import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/core/errors/exceptions.dart';

import '../entities/media_refusal.dart';
import '../entities/picked_video.dart';
import '../entities/publish_event.dart';
import '../entities/publish_session.dart';
import '../ports/video_compressor.dart';

/// Her video made ready to go up (plan §3.4, D1): compressed on the phone,
/// or the original when it can't be (Q2), then held to config's size limit
/// (Q3). The ready file stays in the session, so a retry doesn't compress
/// it again.
class VideoPreparation {
  VideoPreparation(this._compressor, this._session, this._cancel, this._emit);

  final VideoCompressor _compressor;
  final PublishSession _session;
  final UploadCancel _cancel;
  final PublishEmit _emit;
  int _percent = -1;

  /// The file to upload, or null once the attempt ended here: she
  /// cancelled, or it is over [maxBytes].
  Future<PickedVideo?> prepare(PickedVideo video, {int? maxBytes}) async {
    final file = _session.preparedVideo(video.path) ?? await _compress(video);
    if (file == null) return null;
    final size = file.info.sizeBytes;
    if (maxBytes == null || size <= maxBytes) return file;
    _emit(
      PublishVideoRefused(
        path: video.path,
        refusal: MediaRefusal.tooLarge,
        sizeBytes: size,
      ),
    );
    return null;
  }

  Future<PickedVideo?> _compress(PickedVideo video) async {
    _progress(0);
    final CompressedVideo? copy;
    try {
      copy = await _compressor.compress(
        video.path,
        onProgress: _progress,
        cancel: _cancel,
      );
    } on UploadCancelledException {
      _emit(const PublishCancelled());
      return null;
    }
    final file = copy == null ? video : _mp4(copy);
    _session.rememberPrepared(video.path, file);
    if (_cancel.isCancelled) {
      _emit(const PublishCancelled());
      return null;
    }
    _progress(1);
    return file;
  }

  static PickedVideo _mp4(CompressedVideo copy) => PickedVideo(
    path: copy.path,
    container: VideoContainer.mp4,
    info: copy.info,
  );

  /// Per whole percent, as the uploads report theirs.
  void _progress(double progress) {
    final percent = (progress.clamp(0.0, 1.0) * 100).floor();
    if (percent == _percent) return;
    _percent = percent;
    _emit(PublishCompressing(percent / 100));
  }
}
