import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../../core/design_system/widgets/qeran_notice.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../generated/locale_keys.g.dart';
import '../../blocs/composer/post_draft_cubit.dart';
import '../../blocs/composer/post_publish_cubit.dart';
import 'composer_author_line.dart';
import 'composer_draft_notice.dart';
import 'composer_images.dart';
import 'composer_text_area.dart';
import 'composer_toolbar.dart';
import 'composer_video.dart';
import 'publish_strip.dart';

/// Under the composer's header: the strip when there is one (D1–D3), her
/// draft — dimmed to 50 % and locked while her video is prepared or her
/// media goes up (D1, D2) — and the toolbar on the keyboard.
class ComposerBody extends StatelessWidget {
  const ComposerBody({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onRetry,
    required this.onAddImages,
    required this.onAddVideo,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onRetry;
  final VoidCallback onAddImages;
  final VoidCallback onAddVideo;

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<PostDraftCubit>().state;
    final publish = context.watch<PostPublishCubit>().state;
    final dim = publish.busy && publish.progress != null ? 0.5 : 1.0;
    return Column(
      children: [
        ?_strip(context, publish),
        Expanded(
          child: Opacity(
            opacity: dim,
            child: AbsorbPointer(
              absorbing: publish.busy,
              child: _draft(context, draft, publish.busy),
            ),
          ),
        ),
        Opacity(
          opacity: dim,
          child: AbsorbPointer(
            absorbing: publish.busy,
            child: ComposerToolbar(
              draft: draft,
              onImages: onAddImages,
              onVideo: onAddVideo,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _strip(BuildContext context, PostPublishState publish) =>
      switch (publish.status) {
        PublishStatus.failed ||
        PublishStatus.textInvalid => PublishStrip(onRetry: onRetry),
        PublishStatus.compressing => UploadStrip(
          progress: publish.progress ?? 0,
          onCancel: context.read<PostPublishCubit>().cancel,
          label: LocaleKeys.matchmaker_community_preparing_video,
        ),
        PublishStatus.uploading => UploadStrip(
          progress: publish.progress ?? 0,
          onCancel: context.read<PostPublishCubit>().cancel,
        ),
        PublishStatus.publishing when publish.progress != null =>
          const UploadStrip(progress: 1),
        _ => null,
      };

  Widget _draft(BuildContext context, PostDraftState draft, bool locked) {
    final cubit = context.read<PostDraftCubit>();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ComposerAuthorLine(),
          ComposerTextArea(
            controller: controller,
            focusNode: focusNode,
            draft: draft,
            locked: locked,
          ),
          if (draft.rejected) const _Rejected(),
          if (draft.notice != null) ComposerDraftNotice(draft: draft),
          if (draft.images.isNotEmpty) _images(cubit, draft, locked),
          if (draft.video case final video?)
            ComposerVideo(
              video: video,
              maxSeconds: draft.maxVideoSeconds,
              onRemove: locked ? null : cubit.removeVideo,
            ),
        ],
      ),
    );
  }

  Widget _images(PostDraftCubit cubit, PostDraftState draft, bool locked) =>
      ComposerImages(
        images: draft.images,
        maxImages: draft.maxImages,
        locked: locked,
        onAdd: draft.imagesFull ? null : onAddImages,
        onRemove: cubit.removeImage,
        onMove: cubit.moveImage,
      );
}

/// The filter refused the text (BA-A7), under the counter.
class _Rejected extends StatelessWidget {
  const _Rejected();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        0,
        QeranSpacing.s20,
        QeranSpacing.s12,
      ),
      child: QeranNotice(
        icon: Icons.block_rounded,
        text: LocaleKeys.matchmaker_community_rejected.t(context),
        tone: QeranNoticeTone.danger,
      ),
    );
  }
}
