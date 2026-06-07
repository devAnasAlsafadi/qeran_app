import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/enum/snakebar_tybe.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../conversations/domain/entities/matchmaker_conversation.dart';
import '../../../conversations/presentation/blocs/matchmaker_open_chat_state.dart';
import '../blocs/matchmaker_colleague_open_chat_cubit.dart';

/// Provides a [MatchmakerColleagueOpenChatCubit] for the colleague directory and
/// turns its one-shot outcome into a side effect: on
/// [MatchmakerOpenChatOutcome.ready] it pushes the existing matchmaker chat
/// screen (the chat loads its messages by `conversationId`, so it works for
/// colleague↔colleague unchanged); on failure it shows a snackbar. Descendant
/// rows call `open(...)` and read `openingUserId` to drive the inline loader.
class MatchmakerColleagueOpenChatHost extends StatelessWidget {
  const MatchmakerColleagueOpenChatHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MatchmakerColleagueOpenChatCubit>(
      create: (_) => sl<MatchmakerColleagueOpenChatCubit>(),
      child:
          BlocListener<MatchmakerColleagueOpenChatCubit, MatchmakerOpenChatState>(
        listenWhen: (prev, curr) =>
            prev.eventVersion != curr.eventVersion &&
            curr.outcome != MatchmakerOpenChatOutcome.none,
        listener: _onOutcome,
        child: child,
      ),
    );
  }

  void _onOutcome(BuildContext context, MatchmakerOpenChatState state) {
    switch (state.outcome) {
      case MatchmakerOpenChatOutcome.ready:
        NavigationManager.navigateTo(
          context,
          RouteNames.matchmakerUserChat,
          arguments: MatchmakerConversation(
            userId: state.peerUserId ?? '',
            fullName: state.peerName ?? '',
            profileImageUrl: state.peerImageUrl,
            conversationId: state.conversationId ?? 0,
            lastMessageAt: null,
            lastMessagePreview: null,
            unreadCount: 0,
          ),
        );
      case MatchmakerOpenChatOutcome.failure:
        AppSnackBar.show(
          context,
          message: (state.errorMessage ?? LocaleKeys.errors_generic).t(context),
          type: SnackBarType.error,
        );
      case MatchmakerOpenChatOutcome.none:
        break;
    }
  }
}
