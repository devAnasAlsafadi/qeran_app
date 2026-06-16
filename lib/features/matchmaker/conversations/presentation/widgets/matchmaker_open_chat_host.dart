import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/enum/snakebar_tybe.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/matchmaker_conversation.dart';
import '../blocs/matchmaker_open_chat_cubit.dart';
import '../blocs/matchmaker_open_chat_state.dart';

/// Provides a [MatchmakerOpenChatCubit] for a user list and turns its one-shot
/// outcome into a side effect: on [MatchmakerOpenChatOutcome.ready] it pushes
/// the existing matchmaker chat screen — building the thin
/// [MatchmakerConversation] the route accepts (the chat loads its messages by
/// `conversationId`); on [MatchmakerOpenChatOutcome.failure] it shows a
/// snackbar. Descendant cards call `open(...)` on the provided
/// [MatchmakerOpenChatCubit] and read `openingUserId` to drive the loader.
class MatchmakerOpenChatHost extends StatelessWidget {
  const MatchmakerOpenChatHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MatchmakerOpenChatCubit>(
      create: (_) => sl<MatchmakerOpenChatCubit>(),
      child: BlocListener<MatchmakerOpenChatCubit, MatchmakerOpenChatState>(
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
        // Calm "notice" tone, not the loud danger banner — failing to open a
        // chat is a minor heads-up, not a serious error. Friendly text only;
        // the raw server payload here can be a bare code (e.g. "0") or empty.
        AppSnackBar.show(
          context,
          message: LocaleKeys.matchmaker_chat_open_failed.t(context),
          type: SnackBarType.notice,
        );
      case MatchmakerOpenChatOutcome.none:
        break;
    }
  }
}
