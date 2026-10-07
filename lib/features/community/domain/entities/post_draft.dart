import 'picked_image.dart';
import 'picked_video.dart';

/// What she publishes: the text, trimmed, and her images in her order or
/// her video (never both, D11).
class PostDraft {
  final String text;
  final List<PickedImage> images;
  final PickedVideo? video;

  /// Config's `maxVideoSizeBytes` as she published: the video file that
  /// would go up is held to it before anything is sent (Q3). Null: the
  /// server checks alone (S19).
  final int? maxVideoBytes;

  const PostDraft({
    required this.text,
    this.images = const [],
    this.video,
    this.maxVideoBytes,
  });

  /// The draft as sent: the same key means a retry of the same request.
  String get key => [
    text,
    for (final image in images) image.path,
    ?video?.path,
  ].join('\u0000');
}
