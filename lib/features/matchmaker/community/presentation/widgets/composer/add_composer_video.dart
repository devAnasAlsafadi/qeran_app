import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../generated/locale_keys.g.dart';
import '../../blocs/composer/post_draft_cubit.dart';
import '../../services/community_media_picker.dart';
import 'composer_copy.dart';
import 'composer_media_sheet.dart';

/// «فيديو» (C4): «إضافة فيديو» with the gallery, the camera — told to stop
/// at config's limit — and BA-A8's note. The picked file goes to the draft,
/// which checks its type and length before anything is sent (BA-A9).
Future<void> addComposerVideo(BuildContext context) async {
  final draft = context.read<PostDraftCubit>();
  final max = draft.state.maxVideoSeconds;
  final source = await chooseMediaSource(
    context,
    title: LocaleKeys.matchmaker_community_video_sheet_title.t(context),
    note: _note(context, max),
    cameraLabel: LocaleKeys.matchmaker_community_record_video.t(context),
    video: true,
  );
  if (source == null || !context.mounted) return;
  final picker = sl<CommunityMediaPicker>();
  await pickWithAccess(context, () async {
    final path = switch (source) {
      ComposerMediaSource.gallery => await picker.pickVideo(),
      ComposerMediaSource.camera => await picker.recordVideo(
        maxDuration: max == null ? null : Duration(seconds: max),
      ),
    };
    if (path != null) await draft.addVideo(path);
  });
}

/// BA-A8: «المدة القصوى دقيقة واحدة، وتُفحص عند التصوير والاختيار. يُضغط
/// الفيديو على الهاتف قبل رفعه.»; without a limit, the last sentence alone.
String _note(BuildContext context, int? max) => max == null
    ? LocaleKeys.matchmaker_community_video_note_compressed.t(context)
    : LocaleKeys.matchmaker_community_video_note.t(
        context,
        namedArgs: {'duration': durationLimitText(context, max)},
      );
