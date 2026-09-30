import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/widgets/connectivity_banner_host.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/chat_entry_cubit.dart';
import '../blocs/chat_entry_state.dart';
import '../widgets/chat_empty_no_matchmaker.dart';
import '../widgets/chat_error_view.dart';
import '../widgets/chat_header.dart';
import 'chat_conversation_screen.dart';

/// The member's chat with their matchmaker. Resolves `/api/chat/my-matchmaker`
/// and renders one of: loading / no-matchmaker / failure / conversation.
///
/// Every state carries the header. Until the conversation is known it is
/// titled with the matchmaker's role; once it is, it shows her.
///
/// [onBack] puts a back chevron in that header; the pushed page
/// (`MyMatchmakerChatPage`) passes it.
class ChatEntryScreen extends StatelessWidget {
  const ChatEntryScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatEntryCubit>(
      create: (_) => sl<ChatEntryCubit>()..load(),
      child: _ChatEntryView(onBack: onBack),
    );
  }
}

class _ChatEntryView extends StatelessWidget {
  const _ChatEntryView({this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatEntryCubit, ChatEntryState>(
      builder: (context, state) {
        switch (state) {
          case ChatEntryInitial():
          case ChatEntryLoading():
            return _withHeader(context, const Center(child: QeranLoader()));
          case ChatEntryNoMatchmaker():
            return _withHeader(
              context,
              SafeArea(
                top: false,
                child: ChatEmptyNoMatchmaker(
                  onRefresh: context.read<ChatEntryCubit>().refresh,
                ),
              ),
            );
          case ChatEntryFailure():
            return _withHeader(
              context,
              SafeArea(
                top: false,
                child: ChatErrorView(
                  onRetry: context.read<ChatEntryCubit>().refresh,
                ),
              ),
            );
          case ChatEntryReady(:final info):
            return KeyedSubtree(
              key: ValueKey<int>(info.conversationId),
              child: ChatConversationScreen(
                info: info,
                viewer: ChatViewer.member,
                onBack: onBack,
              ),
            );
        }
      },
    );
  }

  Widget _withHeader(BuildContext context, Widget body) {
    return Column(
      children: [
        ChatHeader.title(
          title: LocaleKeys.shell_matchmaker_role.t(context),
          onBack: onBack,
        ),
        const ConnectivityBannerSlot(),
        Expanded(child: body),
      ],
    );
  }
}
