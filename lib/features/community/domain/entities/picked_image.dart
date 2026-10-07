import 'package:qeran/core/domain/upload.dart';

/// An image type the server takes, as its bytes say (plan §3.3).
enum ImageFormat {
  jpeg(extension: 'jpg', mimeType: 'image/jpeg'),
  png(extension: 'png', mimeType: 'image/png');

  const ImageFormat({required this.extension, required this.mimeType});

  /// How the upload names it.
  final String extension;
  final String mimeType;

  /// Whether config's `allowedImageTypes` (lower case, no dot) takes it.
  bool allowedBy(List<String> types) => switch (this) {
    ImageFormat.jpeg => types.contains('jpg') || types.contains('jpeg'),
    ImageFormat.png => types.contains('png'),
  };
}

/// A picked image as it will be sent: named and typed by its bytes, with
/// its size for config's `maxImageSizeBytes`.
class PickedImage {
  final UploadFile file;
  final ImageFormat format;
  final int sizeBytes;

  const PickedImage({
    required this.file,
    required this.format,
    required this.sizeBytes,
  });

  String get path => file.path;
}
