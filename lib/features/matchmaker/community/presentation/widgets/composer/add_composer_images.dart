import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../generated/locale_keys.g.dart';
import '../../blocs/composer/post_draft_cubit.dart';
import '../../services/community_media_picker.dart';
import 'composer_media_sheet.dart';

/// «صور» (C3): «إضافة صور» with the gallery, the camera and the limit, then
/// the phone's own picker — told how many still fit — or camera. What she
/// picked goes to the draft, which checks it.
Future<void> addComposerImages(BuildContext context) async {
  final draft = context.read<PostDraftCubit>();
  final source = await chooseMediaSource(
    context,
    title: LocaleKeys.matchmaker_community_images_sheet_title.t(context),
    note: _note(context, draft.state.maxImages),
    cameraLabel: LocaleKeys.matchmaker_community_take_photo.t(context),
    video: false,
  );
  if (source == null || !context.mounted) return;
  final picker = sl<CommunityMediaPicker>();
  final free = draft.state.freeImageSlots;
  await pickWithAccess(
    context,
    () async => draft.addImages(switch (source) {
      ComposerMediaSource.gallery => await picker.pickImages(limit: free),
      ComposerMediaSource.camera => [?await picker.captureImage()],
    }),
  );
}

/// «حتى {n} صور في المنشور. تُفتح كاميرا الهاتف نفسها.» — the limit only
/// when config gave one.
String _note(BuildContext context, int? max) => [
  if (max != null)
    LocaleKeys.matchmaker_community_images_limit.tPlural(context, max),
  LocaleKeys.matchmaker_community_camera_note.t(context),
].join(' ');
