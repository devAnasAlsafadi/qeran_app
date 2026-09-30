import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/widgets/connectivity_banner_host.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/matchmaker_info.dart';
import '../blocs/conversation_cubit.dart';
import '../blocs/conversation_state.dart';
import '../widgets/chat_error_view.dart';
import '../widgets/chat_header.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_list.dart';
import '../widgets/chat_message_skeleton.dart';
import 'chat_composer_send.dart';
import 'chat_conversation_toasts.dart';

/// Who is reading the conversation. The two sides word a few things
/// differently: the member sees the matchmaker's role under her name, and the
/// empty conversation invites each side in its own app's voice — the
/// matchmaker app's Arabic is feminine, the member app's masculine-generic.
enum ChatViewer { member, matchmaker }

/// One open conversation. Phase 6 adds optimistic outgoing: the
/// composer immediately renders a temp bubble while REST runs in
/// the background; failed temps stay visible with a tap-to-retry
/// affordance wired through to `cubit.retryFailedSend`.
class ChatConversationScreen extends StatelessWidget {
  final MatchmakerInfo info;
  final ChatViewer viewer;

  /// Optional leading back action. When non-null the header renders a back
  /// button that calls it. Both apps push the conversation as a route and
  /// pass it; null leaves the header without one.
  final VoidCallback? onBack;

  /// Optional peer-profile action. Matchmaker conversations provide this so
  /// tapping the user's avatar/name opens their full profile.
  final VoidCallback? onHeaderTap;

  const ChatConversationScreen({
    super.key,
    required this.info,
    required this.viewer,
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
        viewer: viewer,
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
  final ChatViewer viewer;
  final VoidCallback? onBack;
  final VoidCallback? onHeaderTap;
  const _ConversationView({
    required this.info,
    required this.viewer,
    this.onBack,
    this.onHeaderTap,
  });

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
              ChatHeader.peer(
                peer: info,
                // Member-only: the matchmaker's side never reads «خطّابتك».
                subtitle: viewer == ChatViewer.member
                    ? LocaleKeys.shell_matchmaker_role.t(context)
                    : null,
                onBack: onBack,
                onTap: onHeaderTap,
              ),
              // Inert unless the page attaches the offline banner.
              const ConnectivityBannerSlot(),
              Expanded(
                child: _Body(
                  state: state,
                  cubit: cubit,
                  info: info,
                  viewer: viewer,
                ),
              ),
              ChatInputBar(
                onSend: (raw) => sendFromComposer(cubit, raw),
                sendDisabledByCooldown: cooldown,
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
  final ChatViewer viewer;
  const _Body({
    required this.state,
    required this.cubit,
    required this.info,
    required this.viewer,
  });

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
          emptyPromptKey: viewer == ChatViewer.member
              ? LocaleKeys.chat_empty_start_with
              : LocaleKeys.chat_empty_start_with_matchmaker,
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
