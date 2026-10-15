import 'package:flutter/material.dart';

import '../../generated/locale_keys.g.dart';
import '../design_system/widgets/qeran_confirm_dialog.dart';
import '../di/injection_container.dart';
import '../extensions/localization_extension.dart';
import 'app_settings_opener.dart';
import 'media_access.dart';

/// Runs [pick], whose picker calls go through [guardMediaAccess]. A refusal
/// gets [showMediaAccessDenied] on [context] while it is still on screen;
/// backing out, or any other picker error, stays silent.
Future<void> pickWithAccess(
  BuildContext context,
  Future<void> Function() pick,
) async {
  try {
    await pick();
  } on MediaAccessDenied catch (e) {
    if (!context.mounted) return;
    await showMediaAccessDenied(context, e.access);
  }
}

/// «الوصول إلى الكاميرا غير مسموح» (or «إلى الصور»): how to allow it, with
/// «فتح الإعدادات», which opens the app's page in the phone's settings, and
/// «ليس الآن».
Future<void> showMediaAccessDenied(
  BuildContext context,
  MediaAccess access,
) async {
  final camera = access == MediaAccess.camera;
  final open = await QeranConfirmDialog.show(
    context,
    title:
        (camera
                ? LocaleKeys.media_camera_off_title
                : LocaleKeys.media_photos_off_title)
            .t(context),
    message:
        (camera
                ? LocaleKeys.media_camera_off_message
                : LocaleKeys.media_photos_off_message)
            .t(context),
    confirmLabel: LocaleKeys.media_open_settings.t(context),
    cancelLabel: LocaleKeys.media_not_now.t(context),
    icon: camera ? Icons.no_photography_outlined : Icons.hide_image_outlined,
    destructive: false,
  );
  if (open) await sl<AppSettingsOpener>().open();
}
