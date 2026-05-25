import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/features/profile/domain/entities/profile_entry_source.dart';
import 'package:qeran/features/profile/presentation/full_profile_details_args.dart';
import 'package:qeran/features/profile/presentation/other_profile_seed.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/message_send_status.dart';
import 'shared_profile_message_card.dart';

/// One bubble in the chat. Differentiates user (outgoing) vs
/// matchmaker (incoming) by color, alignment and tail. RTL/LTR is
/// handled implicitly via `AlignmentDirectional` — outgoing always
/// hugs the user's end, incoming the other end.
///
/// Shared-profile bubbles are rendered by `SharedProfileMessageCard`
/// (Phase 10) — this file only handles plain text bubbles. Until
/// Phase 10 lands, a profile-share message falls back to its raw
/// content placeholder (never reached in practice for a real send).
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  /// When true, render the subtle "Read" micro-label under the
  /// bubble. The conversation list passes this only for the *last*
  /// outgoing message and only when `isRead == true`.
  final bool showReadReceipt;

  /// Tap on a failed outgoing bubble. Wired in Phase 6.
  final VoidCallback? onRetry;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.showReadReceipt,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final align =
        isMine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart;
    final maxWidth = MediaQuery.of(context).size.width * 0.78;
    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: message.status == MessageSendStatus.failed
                  ? onRetry
                  : null,
              child: _Bubble(message: message, isMine: isMine),
            ),
            const SizedBox(height: 4),
            _Footer(
              message: message,
              isMine: isMine,
              showReadReceipt: showReadReceipt,
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  const _Bubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    // Directional corners so the "tail" points at the speaker side in
    // both LTR and RTL automatically. Outgoing (isMine) tail is at
    // `bottomEnd` — right in LTR, left in RTL — matching the bubble's
    // `AlignmentDirectional.centerEnd` alignment. The incoming
    // variant mirrors the radii.
    final radius = BorderRadiusDirectional.only(
      topStart: const Radius.circular(18),
      topEnd: const Radius.circular(18),
      bottomStart: Radius.circular(isMine ? 18 : 6),
      bottomEnd: Radius.circular(isMine ? 6 : 18),
    );
    final bg = isMine ? AppColors.primary : AppColors.white;
    final fg = isMine ? AppColors.white : AppColors.textPrimary;
    final border = isMine
        ? null
        : Border.all(color: AppColors.primary.withValues(alpha: 0.06));
    final isFailed = message.status == MessageSendStatus.failed;
    // Shared-profile messages drop the text body and render a mini
    // profile card instead. We keep the bubble shell so the speaker
    // (matchmaker vs me) stays unambiguous, but tighten the padding
    // so the card's own inset carries the breathing room.
    final isProfileShare = message.isSharedProfile;
    final padding = isProfileShare
        ? const EdgeInsets.all(6)
        : const EdgeInsets.symmetric(
            horizontal: AppDimens.p12,
            vertical: AppDimens.p8,
          );
    return Opacity(
      opacity: message.status == MessageSendStatus.sending ? 0.6 : 1,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: isFailed
              ? Border.all(color: AppColors.error.withValues(alpha: 0.45))
              : border,
          boxShadow: isMine
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x0A431C33),
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: isProfileShare && message.sharedProfile != null
            ? SharedProfileMessageCard(
                profile: message.sharedProfile!,
                isMine: isMine,
                onTap: () => _openSharedProfile(context, message),
              )
            : Text(
                message.content,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: fg,
                  height: 1.4,
                ),
              ),
      ),
    );
  }
}

/// Opens the reusable Full Profile Details screen with a seed
/// constructed from the chat-side `SharedProfile` mini payload. The
/// `userId` is what backend already carries on the share; the by-id
/// hydration call fills in `placements` + full gallery.
void _openSharedProfile(BuildContext context, ChatMessage message) {
  final shared = message.sharedProfile;
  if (shared == null) return;
  NavigationManager.navigateTo(
    context,
    RouteNames.fullProfileDetails,
    arguments: FullProfileDetailsArgs(
      userId: shared.id,
      initialData: OtherProfileSeed.fromSharedProfile(shared),
      entry: ProfileEntrySource.chat,
    ),
  );
}

class _Footer extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final bool showReadReceipt;
  const _Footer({
    required this.message,
    required this.isMine,
    required this.showReadReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final time = _formatTime(context, message.sentAt);
    final children = <Widget>[
      Text(
        time,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textMuted,
          fontSize: 11,
        ),
      ),
    ];
    if (isMine) {
      switch (message.status) {
        case MessageSendStatus.sending:
          children.add(const SizedBox(width: 6));
          children.add(Text(
            LocaleKeys.chat_message_status_sending.t(context),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ));
        case MessageSendStatus.failed:
          children.add(const SizedBox(width: 6));
          children.add(Text(
            LocaleKeys.chat_message_status_failed.t(context),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.error,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ));
        case MessageSendStatus.sent:
          if (showReadReceipt && message.isRead) {
            children.add(const SizedBox(width: 6));
            children.add(Text(
              LocaleKeys.chat_message_read_label.t(context),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ));
          }
      }
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  String _formatTime(BuildContext context, DateTime ts) {
    final local = ts.toLocal();
    final locale = context.locale.toString();
    try {
      return DateFormat.jm(locale).format(local);
    } catch (_) {
      final hh = local.hour.toString().padLeft(2, '0');
      final mm = local.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
  }
}
