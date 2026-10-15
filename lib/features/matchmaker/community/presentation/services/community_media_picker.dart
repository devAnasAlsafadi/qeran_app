import 'package:image_picker/image_picker.dart';

import '../../../../../core/media/media_access.dart';

/// The phone's own picker and camera for her composer (plan §3.3). Answers
/// file paths; what each file really is, the inspector decides. A refused
/// camera or library throws [MediaAccessDenied] (S9).
abstract class CommunityMediaPicker {
  /// Up to [limit] images from her gallery, in the order she picked them
  /// (empty when she backs out). Null [limit]: no cap from config.
  Future<List<String>> pickImages({int? limit});

  /// One photo from the camera, or null when she backs out.
  Future<String?> captureImage();

  /// One video from her gallery, or null when she backs out.
  Future<String?> pickVideo();

  /// One recording, the camera told to stop at [maxDuration] (some camera
  /// apps ignore it, so the file is checked anyway, BA-A9); null when she
  /// backs out.
  Future<String?> recordVideo({Duration? maxDuration});
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

  @override
  Future<String?> pickVideo() => _guard(
    () async => (await _picker.pickVideo(source: ImageSource.gallery))?.path,
    fallback: null,
  );

  @override
  Future<String?> recordVideo({Duration? maxDuration}) => _guard(
    () async => (await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: maxDuration,
    ))?.path,
    fallback: null,
  );

  Future<String?> _single(ImageSource source) async => (await _picker.pickImage(
    source: source,
    maxWidth: _maxSide,
    maxHeight: _maxSide,
    imageQuality: _quality,
    requestFullMetadata: false,
  ))?.path;

  Future<T> _guard<T>(Future<T> Function() pick, {required T fallback}) =>
      guardMediaAccess(pick, fallback: fallback, tag: 'COMMUNITY');
}
