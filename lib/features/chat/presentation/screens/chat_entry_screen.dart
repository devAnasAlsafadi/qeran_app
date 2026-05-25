import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/theme/app_color.dart';

import '../blocs/chat_entry_cubit.dart';
import '../blocs/chat_entry_state.dart';
import '../widgets/chat_empty_no_matchmaker.dart';
import '../widgets/chat_error_view.dart';
import 'chat_conversation_screen.dart';

/// Tab entry. Resolves `/api/chat/my-matchmaker` and renders one of:
/// loading / no-matchmaker / failure / conversation. Embedded by
/// `HomeScreen` for the Messages bottom-nav tab.
class ChatEntryScreen extends StatelessWidget {
  const ChatEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatEntryCubit>(
      create: (_) => sl<ChatEntryCubit>()..load(),
      child: const _ChatEntryView(),
    );
  }
}

class _ChatEntryView extends StatelessWidget {
  const _ChatEntryView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatEntryCubit, ChatEntryState>(
      builder: (context, state) {
        switch (state) {
          case ChatEntryInitial():
          case ChatEntryLoading():
            return const _Loading();
          case ChatEntryNoMatchmaker():
            return SafeArea(
              child: ChatEmptyNoMatchmaker(
                onRefresh: context.read<ChatEntryCubit>().refresh,
              ),
            );
          case ChatEntryFailure():
            return SafeArea(
              child: ChatErrorView(
                onRetry: context.read<ChatEntryCubit>().refresh,
              ),
            );
          case ChatEntryReady(:final info):
            // Key on conversationId so a reassignment forces a fresh
            // ChatConversationScreen state.
            return KeyedSubtree(
              key: ValueKey<int>(info.conversationId),
              child: ChatConversationScreen(info: info),
            );
        }
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}
