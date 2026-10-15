import 'package:flutter/material.dart';

import '../../../../../../core/design_system/widgets/qeran_options_sheet.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../generated/locale_keys.g.dart';

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
