import 'package:flutter/material.dart';

import '../../../../../../core/design_system/widgets/qeran_options_sheet.dart';
import '../../../../../../core/enum/snakebar_tybe.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../core/utils/app_snackbar.dart';
import '../../../../../../generated/locale_keys.g.dart';
import '../../services/community_media_picker.dart';

enum ComposerMediaSource { gallery, camera }

/// «إضافة صور» or «إضافة فيديو» (C3, C4): the gallery or the camera, then
/// the limits that apply. Null when she closes it.
Future<ComposerMediaSource?> chooseMediaSource(
  BuildContext context, {
  required String title,
  required String note,
  required String cameraLabel,
  required bool video,
}) => QeranOptionsSheet.show<ComposerMediaSource>(
  context,
  title: title,
  note: note,
  options: [
    QeranOption(
      icon: video ? Icons.video_library_outlined : Icons.photo_library_outlined,
      label: LocaleKeys.matchmaker_community_from_gallery.t(context),
      value: ComposerMediaSource.gallery,
    ),
    QeranOption(
      icon: video ? Icons.videocam_outlined : Icons.photo_camera_outlined,
      label: cameraLabel,
      value: ComposerMediaSource.camera,
    ),
  ],
);

/// Runs [pick]; a refused camera or library gets a calm toast (S9). Its
/// copy is read before the pick, while [context] is surely mounted.
Future<void> pickWithAccess(
  BuildContext context,
  Future<void> Function() pick,
) async {
  final camera = LocaleKeys.matchmaker_community_camera_denied.t(context);
  final photos = LocaleKeys.matchmaker_community_photos_denied.t(context);
  try {
    await pick();
  } on MediaAccessDenied catch (e) {
    if (!context.mounted) return;
    AppSnackBar.show(
      context,
      message: e.access == MediaAccess.camera ? camera : photos,
      type: SnackBarType.notice,
    );
  }
}
