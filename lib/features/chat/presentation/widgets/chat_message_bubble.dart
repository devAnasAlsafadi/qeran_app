import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/features/profile/domain/entities/profile_entry_source.dart';
import 'package:qeran/features/profile/presentation/full_profile_details_args.dart';
import 'package:qeran/features/profile/presentation/other_profile_seed.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/message_send_status.dart';
import 'shared_profile_message_card.dart';

/// One bubble in the chat, sender-colored per the Qeran identity:
///   - Outgoing (me)     → wine fill, white text, tail on the end-bottom.
///   - Incoming (other)  → paper fill + wine-08 border, ink text, tail on
///                         the start-bottom.
/// Directional corners keep the tail on the speaker side in LTR + RTL.
/// Shared-profile messages render the cream [SharedProfileMessageCard] as
/// their own bubble (no wine/paper shell).
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  /// When true, render the subtle "Read" micro-label under the bubble.
  /// The conversation list passes this only for the *last* outgoing
  /// message and only when `isRead == true`.
  final bool showReadReceipt;

  /// Tap on a failed outgoing bubble. Wired upstream.
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
    final align = isMine
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart;
    final maxWidth = MediaQuery.of(context).size.width * 0.78;
    final isFailed = message.status == MessageSendStatus.failed;
    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: isFailed ? onRetry : null,
              child: message.isSharedProfile && message.sharedProfile != null
                  ? SharedProfileMessageCard(
                      profile: message.sharedProfile!,
                      isMine: isMine,
                      sharerName: message.senderName,
                      onTap: () => _openSharedProfile(context, message),
                    )
                  : _Bubble(message: message, isMine: isMine),
            ),
            QeranSpacing.vs4,
            _Footer(
              message: message,
              isMine: isMine,
              showReadReceipt: showReadReceipt,
            ),
            if (isFailed) ...[
              QeranSpacing.vs4,
              _FailedRetry(onRetry: onRetry),
            ],
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
    // Directional corners so the "tail" points at the speaker side in both
    // LTR and RTL. Outgoing tail is at bottomEnd; incoming at bottomStart.
    final radius = BorderRadiusDirectional.only(
      topStart: const Radius.circular(16),
      topEnd: const Radius.circular(16),
      bottomStart: Radius.circular(isMine ? 16 : 5),
      bottomEnd: Radius.circular(isMine ? 5 : 16),
    );
    final isFailed = message.status == MessageSendStatus.failed;
    // Resolved HERE, inside build, so reading `context.locale` registers the
    // dependency on easy_localization's inherited widget: switching language
    // with the thread open repaints every system bubble immediately, with no
    // refetch. Caching this in a field or resolving it in the cubit would
    // freeze the text until the next load.
    final isArabic = context.locale.languageCode == 'ar';
    final bg = isMine ? QeranColors.wine : QeranColors.paper;
    final textColor =
        isMine ? QeranColors.paper.withValues(alpha: 0.95) : QeranColors.inkStrong;
    // Incoming paper needs the wine-08 hairline so it reads distinct from the
    // cream canvas; a failed send tints the border danger.
    final border = isMine
        ? (isFailed ? Border.all(color: QeranColors.danger40) : null)
        : Border.all(
            color: isFailed ? QeranColors.danger40 : QeranColors.wine08,
          );
    return Opacity(
      opacity: message.status == MessageSendStatus.sending ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: QeranSpacing.s12,
          vertical: QeranSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: border,
        ),
        child: Text(
          message.displayText(isArabic: isArabic),
          style: QeranTypography.body.copyWith(color: textColor, height: 1.4),
        ),
      ),
    );
  }
}

/// Opens the reusable Full Profile Details screen with a seed
/// constructed from the chat-side `SharedProfile` mini payload.
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
    // Timestamp sits below the bubble on the cream canvas, so we use legible
    // warm/faint inks (not the on-wine gold-40) per side.
    final timeColor = isMine ? QeranColors.goldDeep : QeranColors.inkFaint;
    final children = <Widget>[];
    // Sending → a clock glyph leads the timestamp.
    if (isMine && message.status == MessageSendStatus.sending) {
      children.add(const Icon(
        Icons.schedule_rounded,
        size: 12,
        color: QeranColors.goldDeep,
      ));
      children.add(QeranSpacing.hs4);
    }
    children.add(Text(
      time,
      style: QeranTypography.caption.copyWith(color: timeColor),
    ));
    // Read receipt on the last read outgoing message (kept — a real feature).
    if (isMine &&
        message.status == MessageSendStatus.sent &&
        showReadReceipt &&
        message.isRead) {
      children.add(QeranSpacing.hs4);
      children.add(Text(
        LocaleKeys.chat_message_read_label.t(context),
        style: QeranTypography.caption.copyWith(color: QeranColors.wine60),
      ));
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

/// Tap-to-retry affordance under a failed outgoing bubble.
class _FailedRetry extends StatelessWidget {
  const _FailedRetry({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRetry,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 13,
            color: QeranColors.danger,
          ),
          QeranSpacing.hs4,
          Text(
            LocaleKeys.chat_send_failed_retry.t(context),
            style: QeranTypography.caption.copyWith(
              color: QeranColors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
