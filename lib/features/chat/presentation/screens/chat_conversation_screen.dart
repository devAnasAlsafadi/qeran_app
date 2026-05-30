import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';
import 'package:qeran/features/likes/presentation/widgets/like_blurred_image.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/matchmaker_info.dart';
import '../blocs/conversation_cubit.dart';
import '../blocs/conversation_state.dart';
import '../widgets/chat_error_view.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_lifecycle_wrapper.dart';
import '../widgets/chat_message_list.dart';
import '../widgets/chat_realtime_banner.dart';

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

  const ChatConversationScreen({super.key, required this.info, this.onBack});

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
      child: Builder(
        builder: (ctx) => ChatLifecycleWrapper(
          cubit: ctx.read<ConversationCubit>(),
          child: _ConversationView(info: info, onBack: onBack),
        ),
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
  const _ConversationView({required this.info, this.onBack});

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
        final cooldown = state.sendCooldownUntil != null &&
            DateTime.now().isBefore(state.sendCooldownUntil!);
        return ColoredBox(
          color: QeranColors.creamSurface,
          child: Column(
            children: [
              _Header(info: info, onBack: onBack),
              ChatRealtimeBanner(
                status: state.realtimeStatus,
                hasEverBeenConnected: state.hasEverBeenConnected,
              ),
              Expanded(child: _Body(state: state, cubit: cubit, info: info)),
              ChatInputBar(
                onSend: cubit.sendText,
                sendDisabledByCooldown: cooldown,
              ),
            ],
          ),
        );
      },
    );
  }

  void _onEvent(BuildContext context, ConversationStateData state) {
    switch (state.event) {
      case ConversationEvent.none:
        break;
      case ConversationEvent.sendValidationEmpty:
        AppSnackBar.show(
          context,
          message: LocaleKeys.chat_send_validation_empty.t(context),
          type: SnackBarType.info,
        );
      case ConversationEvent.sendValidationTooLong:
        AppSnackBar.show(
          context,
          message: LocaleKeys.chat_send_validation_too_long.t(context),
          type: SnackBarType.info,
        );
      case ConversationEvent.sendRateLimited:
        AppSnackBar.show(
          context,
          message: LocaleKeys.chat_send_rate_limited.t(context),
          type: SnackBarType.info,
        );
      case ConversationEvent.sendConversationNotFound:
        AppSnackBar.show(
          context,
          message: LocaleKeys.chat_send_conversation_not_found.t(context),
          type: SnackBarType.error,
        );
      case ConversationEvent.sendUnauthorized:
        AppSnackBar.show(
          context,
          message: LocaleKeys.chat_send_unauthorized.t(context),
          type: SnackBarType.error,
        );
      case ConversationEvent.sendFailure:
        // No snackbar — the failed bubble itself carries the
        // tap-to-retry affordance. Showing a toast would double-
        // surface the failure.
        break;
      case ConversationEvent.shareProfileNotFound:
        AppSnackBar.show(
          context,
          message: LocaleKeys.chat_share_profile_not_found.t(context),
          type: SnackBarType.info,
        );
      case ConversationEvent.shareValidation:
        AppSnackBar.show(
          context,
          message: LocaleKeys.chat_share_validation.t(context),
          type: SnackBarType.info,
        );
      case ConversationEvent.shareRateLimited:
        AppSnackBar.show(
          context,
          message: LocaleKeys.chat_share_rate_limited.t(context),
          type: SnackBarType.info,
        );
      case ConversationEvent.shareConversationNotFound:
        AppSnackBar.show(
          context,
          message: LocaleKeys.chat_send_conversation_not_found.t(context),
          type: SnackBarType.error,
        );
      case ConversationEvent.shareUnauthorized:
        AppSnackBar.show(
          context,
          message: LocaleKeys.chat_send_unauthorized.t(context),
          type: SnackBarType.error,
        );
      case ConversationEvent.shareFailure:
        AppSnackBar.show(
          context,
          message: LocaleKeys.chat_share_failure.t(context),
          type: SnackBarType.error,
        );
      case ConversationEvent.shareSuccess:
        // No snackbar — the inserted message itself confirms.
        break;
    }
  }
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
        return const Center(child: QeranLoader());
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

/// Leading back affordance for the header — shown only when
/// [ChatConversationScreen.onBack] is set (pushed-route usage). Transparent
/// host since the header is already on a paper surface.
class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onBack,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Icon(
              Icons.arrow_back_rounded,
              color: QeranColors.wine,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final MatchmakerInfo info;
  final VoidCallback? onBack;
  const _Header({required this.info, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: QeranColors.paper,
        border: Border(
          bottom: BorderSide(color: QeranColors.wine08),
        ),
        boxShadow: QeranShadows.e1,
      ),
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s16,
        QeranSpacing.s12,
        QeranSpacing.s16,
        QeranSpacing.s12,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (onBack != null) ...[
              _HeaderBackButton(onBack: onBack!),
              QeranSpacing.hs4,
            ],
            // Gold ring around the avatar — the brand's quiet
            // presence signal for the person on the other side.
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: QeranColors.gold, width: 1.2),
              ),
              child: LikeBlurredImage(
                url: info.profileImageUrl,
                blur: false,
                size: 40,
                fallbackIcon: Icons.person_rounded,
              ),
            ),
            QeranSpacing.hs12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.name,
                    style: QeranTypography.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  QeranSpacing.vs4,
                  Text(
                    LocaleKeys.chat_header_default_subtitle.t(context),
                    style: QeranTypography.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
