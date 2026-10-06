import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/community/domain/entities/community_viewer.dart';
import 'package:qeran/features/community/presentation/screens/community_guidelines_page.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_app_bar.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_confirm_dialog.dart';
import '../../../../../core/design_system/widgets/qeran_notice.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../blocs/composer/post_draft_cubit.dart';
import '../blocs/composer/post_publish_cubit.dart';
import '../widgets/composer/composer_author_line.dart';
import '../widgets/composer/composer_text_area.dart';
import '../widgets/composer/publish_strip.dart';

/// Her composer (C1–C11, D3, D5, BA-A7), text for now: «منشور جديد» with a
/// × and «نشر», her line, the text with its counter. Closing a draft with
/// something in it asks first (C11); while it publishes, nothing closes it.
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
    if (!context.read<PostDraftCubit>().state.canPublish) return;
    context.read<PostPublishCubit>().publish(_text.text);
  }

  /// × or back: an empty draft closes; one with something in it asks (C11).
  Future<void> _close() async {
    if (context.read<PostPublishCubit>().state.busy) return;
    final navigator = Navigator.of(context);
    if (context.read<PostDraftCubit>().state.isEmpty || await _discard()) {
      navigator.pop();
    }
  }

  Future<bool> _discard() => QeranConfirmDialog.show(
    context,
    title: LocaleKeys.matchmaker_community_discard_title.t(context),
    message: LocaleKeys.matchmaker_community_discard_body.t(context),
    confirmLabel: LocaleKeys.matchmaker_community_discard.t(context),
    cancelLabel: LocaleKeys.matchmaker_community_keep_writing.t(context),
    icon: Icons.edit_off_rounded,
  );

  /// What the server said: closes with the post (D5), keeps the draft for
  /// an edit (BA-A7), or asks for the new guidelines first (§3.1).
  Future<void> _onAnswer(BuildContext context, PostPublishState state) async {
    switch (state.status) {
      case PublishStatus.published:
        Navigator.of(context).pop(state.post);
      case PublishStatus.rejected:
        context.read<PostDraftCubit>().refused();
        _focus.requestFocus();
      case PublishStatus.guidelinesRequired:
        await openCommunityGuidelines(
          context,
          viewer: CommunityViewer.matchmaker,
        );
      case PublishStatus.idle ||
          PublishStatus.publishing ||
          PublishStatus.failed:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<PostDraftCubit>().state;
    final publish = context.watch<PostPublishCubit>().state;
    return BlocListener<PostPublishCubit, PostPublishState>(
      listenWhen: (previous, current) =>
          previous.attempt != current.attempt ||
          previous.status != current.status,
      listener: _onAnswer,
      child: PopScope(
        canPop: draft.isEmpty && !publish.busy,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _close();
        },
        child: Scaffold(
          backgroundColor: QeranColors.paper,
          appBar: _appBar(context, draft, publish),
          body: _body(draft, publish),
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(
    BuildContext context,
    PostDraftState draft,
    PostPublishState publish,
  ) => QeranAppBar(
    title: LocaleKeys.matchmaker_community_new_post.t(context),
    close: true,
    onBack: _close,
    background: QeranColors.paper,
    actions: [
      Padding(
        padding: const EdgeInsetsDirectional.only(end: QeranSpacing.s12),
        child: QeranButton(
          label: LocaleKeys.matchmaker_community_publish.t(context),
          onPressed: draft.canPublish ? _publish : null,
          variant: QeranButtonVariant.primaryGold,
          size: QeranButtonSize.compact,
          fullWidth: false,
          loading: publish.busy,
        ),
      ),
    ],
  );

  Widget _body(PostDraftState draft, PostPublishState publish) => Column(
    children: [
      if (publish.status == PublishStatus.failed)
        PublishStrip(onRetry: _publish),
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ComposerAuthorLine(),
              ComposerTextArea(
                controller: _text,
                focusNode: _focus,
                draft: draft,
                locked: publish.busy,
              ),
              if (draft.rejected) _rejected(),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _rejected() => Padding(
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
