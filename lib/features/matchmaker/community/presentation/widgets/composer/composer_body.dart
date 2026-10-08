import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../../core/design_system/widgets/qeran_notice.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../generated/locale_keys.g.dart';
import '../../blocs/composer/post_draft_cubit.dart';
import '../../blocs/composer/post_publish_cubit.dart';
import 'composer_author_line.dart';
import 'composer_counter.dart';
import 'composer_draft_notice.dart';
import 'composer_images.dart';
import 'composer_text_area.dart';
import 'composer_toolbar.dart';
import 'composer_video.dart';
import 'publish_strip.dart';

/// Under the composer's header: the strip when there is one (D1–D3, BA-A6), her
/// draft — filling the space down to the counter, which sits over the
/// toolbar on the keyboard — all dimmed to 50 % and locked while her video is
/// prepared or her media goes up (D1, D2).
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
          child: _dimmed(
            dim,
            publish.busy,
            _draft(context, draft, publish.busy),
          ),
        ),
        _dimmed(dim, publish.busy, _bottom(draft)),
      ],
    );
  }

  /// The counter over the toolbar, which sits on the keyboard.
  Widget _bottom(PostDraftState draft) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ComposerCounter(draft: draft),
      ComposerToolbar(draft: draft, onImages: onAddImages, onVideo: onAddVideo),
    ],
  );

  /// Dimmed to [opacity], and closed to touch while [busy].
  static Widget _dimmed(double opacity, bool busy, Widget child) => Opacity(
    opacity: opacity,
    child: AbsorbPointer(absorbing: busy, child: child),
  );

  Widget? _strip(BuildContext context, PostPublishState publish) =>
      switch (publish.status) {
        PublishStatus.failed ||
        PublishStatus.textInvalid => PublishStrip(onRetry: onRetry),
        PublishStatus.videoUnavailable => PublishStrip(
          onRetry: onRetry,
          message: LocaleKeys.matchmaker_community_video_unavailable,
        ),
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

  /// Her draft, scrolling as one when it's long. The space under it is where
  /// she writes too: a tap there puts the cursor at the end of her text.
  Widget _draft(BuildContext context, PostDraftState draft, bool locked) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _content(context, draft, locked)),
        SliverFillRemaining(
          hasScrollBody: false,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _writeAtEnd,
          ),
        ),
      ],
    );
  }

  Widget _content(BuildContext context, PostDraftState draft, bool locked) {
    final cubit = context.read<PostDraftCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ComposerAuthorLine(),
        ComposerTextArea(
          controller: controller,
          focusNode: focusNode,
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
    );
  }

  void _writeAtEnd() {
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
    focusNode.requestFocus();
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

/// The filter refused the text (BA-A7), under it.
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
