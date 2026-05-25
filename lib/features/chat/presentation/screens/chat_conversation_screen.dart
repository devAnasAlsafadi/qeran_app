import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
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
  const ChatConversationScreen({super.key, required this.info});

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
          child: _ConversationView(info: info),
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
  const _ConversationView({required this.info});

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
        return Column(
          children: [
            _Header(info: info),
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
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
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

class _Header extends StatelessWidget {
  final MatchmakerInfo info;
  const _Header({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.06),
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10431C33),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDimens.p16,
        AppDimens.p12,
        AppDimens.p16,
        AppDimens.p12,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            LikeBlurredImage(
              url: info.profileImageUrl,
              blur: false,
              size: 44,
              fallbackIcon: Icons.person_rounded,
            ),
            const SizedBox(width: AppDimens.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.name,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    LocaleKeys.chat_header_default_subtitle.t(context),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
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
