import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/community/domain/entities/community_viewer.dart';
import 'package:qeran/features/community/domain/entities/post_draft.dart';
import 'package:qeran/features/community/presentation/screens/community_guidelines_page.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../blocs/composer/post_draft_cubit.dart';
import '../blocs/composer/post_publish_cubit.dart';
import '../widgets/composer/add_composer_images.dart';
import '../widgets/composer/add_composer_video.dart';
import '../widgets/composer/composer_app_bar.dart';
import '../widgets/composer/composer_body.dart';
import '../widgets/composer/composer_dialogs.dart';

/// Her composer (C1–C11, D2–D5, BA-A7): «منشور جديد» with a × and «نشر»,
/// her line, the text with its counter, her images. Closing a draft with
/// something in it asks first (C11); while her media goes up, × asks to
/// stop it (D2b); while the post is being made, nothing closes it.
class PostComposerScreen extends StatefulWidget {
  const PostComposerScreen({super.key});

  @override
  State<PostComposerScreen> createState() => _PostComposerScreenState();
}

class _PostComposerScreenState extends State<PostComposerScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _text.addListener(() => context.read<PostDraftCubit>().edit(_text.text));
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _publish() {
    final draft = context.read<PostDraftCubit>().state;
    if (!draft.canPublish) return;
    context.read<PostPublishCubit>().publish(
      PostDraft(text: _text.text, images: draft.images),
    );
  }

  /// × or back: stopping an upload asks (D2b); an empty draft closes; one
  /// with something in it asks (C11).
  Future<void> _close() async {
    final publish = context.read<PostPublishCubit>();
    if (publish.state.cancellable) {
      if (await confirmCancelUpload(context)) publish.cancel();
      return;
    }
    if (publish.state.busy) return;
    final navigator = Navigator.of(context);
    if (context.read<PostDraftCubit>().state.isEmpty ||
        await confirmDiscardDraft(context)) {
      navigator.pop();
    }
  }

  /// What the server said: closes with the post (D5), keeps the draft for
  /// an edit (BA-A7, Q3, C10, C7), or asks for the new guidelines first
  /// (§3.1).
  Future<void> _onAnswer(BuildContext context, PostPublishState state) async {
    final draft = context.read<PostDraftCubit>();
    switch (state.status) {
      case PublishStatus.published:
        Navigator.of(context).pop(state.post);
      case PublishStatus.rejected:
        draft.refused();
        _focus.requestFocus();
      case PublishStatus.guidelinesRequired:
        await openCommunityGuidelines(
          context,
          viewer: CommunityViewer.matchmaker,
        );
      case PublishStatus.refused:
        draft.imageRefused(path: state.refusedPath, refusal: state.refusal!);
      case PublishStatus.textInvalid:
        await draft.loadConfig();
      case PublishStatus.idle ||
          PublishStatus.uploading ||
          PublishStatus.publishing ||
          PublishStatus.failed:
        break;
    }
  }

  static bool _isAnswer(PostPublishState previous, PostPublishState now) =>
      previous.attempt != now.attempt || previous.status != now.status;

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<PostDraftCubit>().state;
    final publish = context.watch<PostPublishCubit>().state;
    return BlocListener<PostPublishCubit, PostPublishState>(
      listenWhen: _isAnswer,
      listener: _onAnswer,
      child: PopScope(
        canPop: draft.isEmpty && !publish.busy,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _close();
        },
        child: Scaffold(
          backgroundColor: QeranColors.paper,
          appBar: composerAppBar(
            context,
            onClose: _close,
            onPublish: draft.canPublish ? _publish : null,
            busy: publish.busy,
          ),
          body: ComposerBody(
            controller: _text,
            focusNode: _focus,
            onRetry: _publish,
            onAddImages: () => addComposerImages(context),
            onAddVideo: () => addComposerVideo(context),
          ),
        ),
      ),
    );
  }
}
