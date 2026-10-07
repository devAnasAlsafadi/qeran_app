import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/app_logger.dart';

/// What she refused the app: the camera, or her photos (S9).
enum MediaAccess { camera, photos }

/// Thrown when the system refused access; the composer says how to allow it.
class MediaAccessDenied implements Exception {
  final MediaAccess access;
  const MediaAccessDenied(this.access);
}

/// The phone's own picker and camera for her composer (plan §3.3). Answers
/// file paths; what each file really is, the inspector decides.
abstract class CommunityMediaPicker {
  /// Up to [limit] images from her gallery, in the order she picked them
  /// (empty when she backs out). Null [limit]: no cap from config.
  Future<List<String>> pickImages({int? limit});

  /// One photo from the camera, or null when she backs out.
  Future<String?> captureImage();
}

/// [CommunityMediaPicker] over `image_picker`. Every image is re-encoded at
/// 1600 px and quality 85 (Q4): that turns a HEIC into a JPEG on both
/// platforms, and the server's display copy is 1600 anyway. No full
/// metadata, so iOS asks for no library permission to pick.
class ImagePickerCommunityMediaPicker implements CommunityMediaPicker {
  ImagePickerCommunityMediaPicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const double _maxSide = 1600;
  static const int _quality = 85;

  @override
  Future<List<String>> pickImages({int? limit}) => _guard(() async {
    // The multi-picker takes a limit of 2 or more; one slot left is one pick.
    if (limit == 1) {
      final one = await _single(ImageSource.gallery);
      return [?one];
    }
    final picked = await _picker.pickMultiImage(
      maxWidth: _maxSide,
      maxHeight: _maxSide,
      imageQuality: _quality,
      limit: limit,
      requestFullMetadata: false,
    );
    return [for (final file in picked) file.path];
  }, fallback: const []);

  @override
  Future<String?> captureImage() =>
      _guard(() => _single(ImageSource.camera), fallback: null);

  Future<String?> _single(ImageSource source) async => (await _picker.pickImage(
    source: source,
    maxWidth: _maxSide,
    maxHeight: _maxSide,
    imageQuality: _quality,
    requestFullMetadata: false,
  ))?.path;

  /// A refusal becomes [MediaAccessDenied]; any other platform error (no
  /// camera, the picker already open) is logged and reads as backing out.
  Future<T> _guard<T>(Future<T> Function() pick, {required T fallback}) async {
    try {
      return await pick();
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'camera_access_denied':
          throw const MediaAccessDenied(MediaAccess.camera);
        case 'photo_access_denied':
          throw const MediaAccessDenied(MediaAccess.photos);
      }
      AppLogger.warning('Picker failed: ${e.code}', tag: 'COMMUNITY');
      return fallback;
    }
  }
}
