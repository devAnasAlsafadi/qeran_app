import '../entities/media_upload_outcome.dart';
import '../entities/picked_image.dart';
import '../entities/post_publish_outcome.dart';
import '../entities/publish_event.dart';
import 'upload_attempt.dart';

/// One attempt's images (6.7): each sent once, one after another in her
/// order (S5), progress by bytes across all of them.
class ImageUploads extends UploadAttempt {
  ImageUploads(super.repository, super.session, super.cancel, super.emit);

  int _total = 0;

  /// Their ids in her order, or null once the attempt ended here.
  Future<List<String>?> upload(List<PickedImage> images) async {
    if (images.isEmpty) return const [];
    _total = images.fold(0, (sum, image) => sum + image.sizeBytes);
    var done = 0;
    final ids = <String>[];
    progress(0, _total);
    for (final image in images) {
      final id = session.uploadedId(image.path) ?? await _send(image, done);
      if (id == null) return null;
      done += image.sizeBytes;
      ids.add(id);
      progress(done, _total);
    }
    if (!cancel.isCancelled) return ids;
    cancelled();
    return null;
  }

  Future<String?> _send(PickedImage image, int done) async {
    final result = await repository.uploadImage(
      image.file,
      cancel: cancel,
      onProgress: (sent, total) => progress(
        done + (total == 0 ? 0 : image.sizeBytes * sent ~/ total),
        _total,
      ),
    );
    return result.fold(stopped, (outcome) {
      switch (outcome) {
        case MediaUploaded(:final value):
          session.remember(image.path, value);
          return value;
        case MediaUploadRefused(:final refusal):
          emit(PublishImageRefused(path: image.path, refusal: refusal));
        case MediaVideoUnavailable():
          emit(const PublishAnswered(PostVideoUnavailable()));
      }
      return null;
    });
  }
}
