import 'picked_image.dart';

/// What she publishes: the text, trimmed, and her images in her order (a
/// video joins in sub-step 13).
class PostDraft {
  final String text;
  final List<PickedImage> images;

  const PostDraft({required this.text, this.images = const []});

  /// The draft as sent: the same key means a retry of the same request.
  String get key =>
      [text, for (final image in images) image.path].join('\u0000');
}
