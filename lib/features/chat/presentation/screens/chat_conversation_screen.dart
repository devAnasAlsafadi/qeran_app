import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/matchmaker_info.dart';
import '../../domain/entities/realtime_status.dart';
import '../blocs/conversation_cubit.dart';
import '../blocs/conversation_state.dart';
import '../widgets/chat_error_view.dart';
import '../widgets/chat_header.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_list.dart';
import '../widgets/chat_message_skeleton.dart';
import '../widgets/nav_aware_composer.dart';
import 'chat_conversation_toasts.dart';

/// One open conversation. Phase 6 adds optimistic outgoing: the
/// composer immediately renders a temp bubble while REST runs in
/// the background; failed temps stay visible with a tap-to-retry
/// affordance wired through to `cubit.retryFailedSend`.
class ChatConversationScreen extends StatelessWidget {
  final MatchmakerInfo info;

  /// Optional leading back action. When non-null the header renders a back
  /// button that calls it — used when this screen is PUSHED as a route
  /// (e.g. the matchmaker opening a conversation). Null on the user Messages
  /// tab (no route to pop), so that tab renders exactly as before.
  final VoidCallback? onBack;

  /// Optional peer-profile action. Matchmaker conversations provide this so
  /// tapping the user's avatar/name opens their full profile.
  final VoidCallback? onHeaderTap;

  const ChatConversationScreen({
    super.key,
    required this.info,
    this.onBack,
    this.onHeaderTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ConversationCubit>(
      create: (ctx) {
        final myUserId = _readMyId(ctx);
        return sl<ConversationCubit>(
          param1: info.conversationId,
          param2: myUserId,
        )..init();
      },
      // No realtime lifecycle here — the shell owns the session (see
      // `ChatRealtimeHost`). This screen only reads the streams.
      child: _ConversationView(
        info: info,
        onBack: onBack,
        onHeaderTap: onHeaderTap,
      ),
    );
  }

  static String _readMyId(BuildContext context) {
    try {
      final s = context.read<UserSessionCubit>().state;
      if (s is UserSessionAuthenticated) {
        return s.user.id;
      }
    } catch (_) {
      // No session in test scope.
    }
    return '';
  }
}

class _ConversationView extends StatelessWidget {
  final MatchmakerInfo info;
  final VoidCallback? onBack;
  final VoidCallback? onHeaderTap;
  const _ConversationView({required this.info, this.onBack, this.onHeaderTap});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConversationCubit, ConversationStateData>(
      // Only fire on event-version bumps so unrelated state changes
      // (pagination, new message arrival, etc.) don't re-trigger
      // toasts.
      listenWhen: (prev, curr) =>
          prev.eventVersion != curr.eventVersion &&
          curr.event != ConversationEvent.none,
      listener: _onEvent,
      builder: (context, state) {
        final cubit = context.read<ConversationCubit>();
        final cooldown =
            state.sendCooldownUntil != null &&
            DateTime.now().isBefore(state.sendCooldownUntil!);
        return ColoredBox(
          color: QeranColors.creamCanvas,
          child: Column(
            children: [
              ChatHeader(
                info: info,
                onBack: onBack,
                onTap: onHeaderTap,
                isActive: state.realtimeStatus == RealtimeStatus.connected,
              ),
              Expanded(
                child: _Body(state: state, cubit: cubit, info: info),
              ),
              NavAwareComposer(
                child: ChatInputBar(
                  onSend: cubit.sendText,
                  sendDisabledByCooldown: cooldown,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onEvent(BuildContext context, ConversationStateData state) =>
      showConversationEventToast(context, state.event);
}

class _Body extends StatelessWidget {
  final ConversationStateData state;
  final ConversationCubit cubit;
  final MatchmakerInfo info;
  const _Body({required this.state, required this.cubit, required this.info});

  @override
  Widget build(BuildContext context) {
    switch (state.initialStatus) {
      case ConversationAsyncStatus.initial:
      case ConversationAsyncStatus.loading:
        return const ChatMessageSkeleton();
      case ConversationAsyncStatus.failure:
        return ChatErrorView(
          onRetry: cubit.init,
          titleKey: LocaleKeys.chat_messages_load_failed,
          retryKey: LocaleKeys.chat_entry_retry,
        );
      case ConversationAsyncStatus.loaded:
        return ChatMessageList(
          messages: state.messages,
          me: cubit.myUserId,
          peerName: info.name,
          hasMore: state.hasMore,
          isPaginating: state.isPaginating,
          paginationFailed: state.paginationFailed,
          onLoadMore: cubit.loadMore,
          onRetryPagination: cubit.retryPagination,
          onRefresh: cubit.refresh,
          onRetryFailedSend: cubit.retryFailedSend,
        );
    }
  }
}
