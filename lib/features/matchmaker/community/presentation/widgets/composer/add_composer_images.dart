import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/design_system/widgets/qeran_options_sheet.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/enum/snakebar_tybe.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../core/utils/app_snackbar.dart';
import '../../../../../../generated/locale_keys.g.dart';
import '../../blocs/composer/post_draft_cubit.dart';
import '../../services/community_media_picker.dart';

enum _ImageSource { gallery, camera }

/// «صور» (C3): «إضافة صور» with the gallery and the camera and the limit,
/// then the phone's own picker — told how many still fit — or camera. What
/// she picked goes to the draft, which checks it. A refused permission gets
/// a calm toast (S9).
Future<void> addComposerImages(BuildContext context) async {
  final draft = context.read<PostDraftCubit>();
  final source = await _chooseSource(context, draft.state.maxImages);
  if (source == null || !context.mounted) return;
  final denied = _deniedText(context);
  try {
    await draft.addImages(await _pick(source, draft.state.freeImageSlots));
  } on MediaAccessDenied catch (e) {
    if (!context.mounted) return;
    AppSnackBar.show(
      context,
      message: denied(e.access),
      type: SnackBarType.notice,
    );
  }
}

/// «إضافة صور»: the gallery or the camera, and the limit.
Future<_ImageSource?> _chooseSource(BuildContext context, int? max) =>
    QeranOptionsSheet.show<_ImageSource>(
      context,
      title: LocaleKeys.matchmaker_community_images_sheet_title.t(context),
      note: _note(context, max),
      options: [
        QeranOption(
          icon: Icons.photo_library_rounded,
          label: LocaleKeys.matchmaker_community_from_gallery.t(context),
          value: _ImageSource.gallery,
        ),
        QeranOption(
          icon: Icons.photo_camera_rounded,
          label: LocaleKeys.matchmaker_community_take_photo.t(context),
          value: _ImageSource.camera,
        ),
      ],
    );

Future<List<String>> _pick(_ImageSource source, int? free) async {
  final picker = sl<CommunityMediaPicker>();
  return switch (source) {
    _ImageSource.gallery => picker.pickImages(limit: free),
    _ImageSource.camera => [?await picker.captureImage()],
  };
}

/// «حتى {n} صور في المنشور. تُفتح كاميرا الهاتف نفسها.» — the limit only
/// when config gave one.
String _note(BuildContext context, int? max) => [
  if (max != null)
    LocaleKeys.matchmaker_community_images_limit.tPlural(context, max),
  LocaleKeys.matchmaker_community_camera_note.t(context),
].join(' ');

String Function(MediaAccess) _deniedText(BuildContext context) {
  final camera = LocaleKeys.matchmaker_community_camera_denied.t(context);
  final photos = LocaleKeys.matchmaker_community_photos_denied.t(context);
  return (access) => access == MediaAccess.camera ? camera : photos;
}
