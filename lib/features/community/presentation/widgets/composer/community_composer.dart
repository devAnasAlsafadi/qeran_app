import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/auth/presentation/reader_copy.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/enum/snakebar_tybe.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../../../../core/widgets/bottom_chrome_inset.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../blocs/composer/community_composer_cubit.dart';
import '../../blocs/composer/community_composer_state.dart';
import '../../screens/community_guidelines_page.dart';
import '../../screens/community_name_gate_page.dart';
import 'composer_field_row.dart';
import 'composer_notices.dart';
import 'composer_reply_strip.dart';

/// The bar at the foot of the post screen (D1–D10, C10): the comment field
/// — or, answering a comment, the reply strip above it — and the filter's
/// banner after a refusal. A member who can't take part yet ([readOnly])
/// sees why instead of a field. It sits on the safe area or right on the
/// keyboard, and toasts stand clear of it. The name and guidelines steps
/// open over it when the member owes them (F1–F7).
class CommunityComposer extends StatefulWidget {
  const CommunityComposer({super.key, required this.readOnly});

  final bool readOnly;

  @override
  State<CommunityComposer> createState() => _CommunityComposerState();
}

class _CommunityComposerState extends State<CommunityComposer> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // The counter, the edge, the send button and the direction follow it.
    _controller.addListener(_onText);
  }

  void _onText() => setState(() {});

  @override
  void dispose() {
    _controller
      ..removeListener(_onText)
      ..dispose();
    _focus.dispose();
    super.dispose();
  }

  /// The field clears at once (D5); the text comes back if it didn't go.
  void _send() {
    final text = _controller.text;
    _controller.clear();
    context.read<CommunityComposerCubit>().submit(text);
  }

  @override
  Widget build(BuildContext context) {
    return BottomChromeInset(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: QeranColors.creamCanvas,
          border: Border(top: BorderSide(color: QeranColors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: widget.readOnly
              ? const ComposerReadOnlyNotice()
              : BlocConsumer<CommunityComposerCubit, CommunityComposerState>(
                  listenWhen: (previous, current) =>
                      previous.eventVersion != current.eventVersion,
                  listener: _onEvent,
                  builder: _composer,
                ),
        ),
      ),
    );
  }

  Widget _composer(BuildContext context, CommunityComposerState state) {
    final replyTo = state.replyTo;
    final cubit = context.read<CommunityComposerCubit>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (replyTo != null)
          ComposerReplyStrip(
            name: replyTo.author.displayName,
            onClose: cubit.cancelReply,
          ),
        if (state.filtered) const ComposerRejectedBanner(),
        ComposerFieldRow(
          controller: _controller,
          focusNode: _focus,
          state: state,
          onSend: _send,
          onWaitingTap: cubit.startWriting,
        ),
      ],
    );
  }

  void _onEvent(BuildContext context, CommunityComposerState state) {
    if (state.event == CommunityComposerEvent.focus) {
      // After this frame: the field may only now have stopped waiting.
      return WidgetsBinding.instance.addPostFrameCallback(
        (_) => mounted ? _focus.requestFocus() : null,
      );
    }
    _giveBack(state.restore);
    final step = switch (state.event) {
      CommunityComposerEvent.openNameGate => openCommunityNameGate,
      CommunityComposerEvent.openGuidelines => openCommunityGuidelines,
      _ => null,
    };
    if (step != null) {
      _take(step);
      return;
    }
    _toastFor(state.event);
  }

  /// What a refusal says, when it says something.
  void _toastFor(CommunityComposerEvent event) {
    final toast = switch (event) {
      CommunityComposerEvent.rateLimited =>
        LocaleKeys.community_rate_limited.forReader(
          her: LocaleKeys.community_her_rate_limited,
        ),
      CommunityComposerEvent.notApproved =>
        LocaleKeys.community_read_only_comment,
      CommunityComposerEvent.contentGone => LocaleKeys.community_content_gone,
      _ => null,
    };
    if (toast == null) return;
    AppSnackBar.show(
      context,
      message: toast.t(context),
      type: SnackBarType.notice,
    );
  }

  /// Opens [step] over the post screen, and tells the composer how it went.
  Future<void> _take(Future<bool> Function(BuildContext) step) async {
    final cubit = context.read<CommunityComposerCubit>();
    final done = await step(context);
    if (mounted) cubit.stepClosed(done: done);
  }

  /// [text] back in the field — unless the member has started another.
  void _giveBack(String? text) {
    if (text == null || _controller.text.trim().isNotEmpty) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
