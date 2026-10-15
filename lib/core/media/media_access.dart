import 'package:flutter/services.dart';

import '../app_logger.dart';

/// What the phone refused the app: the camera, or the photo library.
enum MediaAccess { camera, photos }

/// Thrown by [guardMediaAccess] when the phone refused [access];
/// `pickWithAccess` turns it into the settings dialog.
class MediaAccessDenied implements Exception {
  final MediaAccess access;
  const MediaAccessDenied(this.access);
}

/// Runs one `image_picker` call. A refusal becomes [MediaAccessDenied]:
/// denied by the member, or restricted (Screen Time, a managed phone; iOS
/// only). Any other platform error (no camera, the picker already open) is
/// logged and reads as backing out, so the caller gets [fallback].
Future<T> guardMediaAccess<T>(
  Future<T> Function() pick, {
  required T fallback,
  String tag = 'MEDIA',
}) async {
  try {
    return await pick();
  } on PlatformException catch (e) {
    final refused = _refused(e.code);
    if (refused != null) throw MediaAccessDenied(refused);
    AppLogger.warning('Picker failed: ${e.code}', tag: tag);
    return fallback;
  }
}

/// The plugin's refusal codes: Android sends only `camera_access_denied`
/// (its gallery is the system Photo Picker, which needs no permission).
MediaAccess? _refused(String code) => switch (code) {
  'camera_access_denied' || 'camera_access_restricted' => MediaAccess.camera,
  'photo_access_denied' || 'photo_access_restricted' => MediaAccess.photos,
  _ => null,
};
