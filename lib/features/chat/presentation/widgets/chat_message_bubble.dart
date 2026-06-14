import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
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

/// One bubble in the chat. Per the Qeran identity:
///   - Inbound (matchmaker)  → gold background, wine text.
///   - Outbound (me)         → paper background, wine text, e1 lift.
/// Both use a directional tail that points at the speaker side in both
/// LTR and RTL via `BorderRadiusDirectional`.
///
/// Shared-profile bubbles are rendered by `SharedProfileMessageCard` —
/// this file only handles plain text bubbles.
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
            QeranSpacing.vs4,
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
    // `bottomEnd`; incoming mirrors.
    final radius = BorderRadiusDirectional.only(
      topStart: const Radius.circular(18),
      topEnd: const Radius.circular(18),
      bottomStart: Radius.circular(isMine ? 18 : 6),
      bottomEnd: Radius.circular(isMine ? 6 : 18),
    );
    // Identity: my messages are wine with paper text; incoming
    // (matchmaker) messages are paper with ink text.
    final bg = isMine ? QeranColors.wine : QeranColors.paper;
    final textColor = isMine ? QeranColors.paper : QeranColors.inkStrong;
    final isFailed = message.status == MessageSendStatus.failed;
    // Shared-profile messages drop the text body and render a mini
    // profile card instead. We keep the bubble shell so the speaker
    // stays unambiguous, but tighten the padding so the card's own
    // inset carries the breathing room.
    final isProfileShare = message.isSharedProfile;
    final padding = isProfileShare
        ? const EdgeInsets.all(6)
        : const EdgeInsets.symmetric(
            horizontal: QeranSpacing.s12,
            vertical: QeranSpacing.s8,
          );
    return Opacity(
      opacity: message.status == MessageSendStatus.sending ? 0.6 : 1,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: isFailed
              ? Border.all(color: QeranColors.danger.withValues(alpha: 0.45))
              : null,
          boxShadow: QeranShadows.e1,
        ),
        child: isProfileShare && message.sharedProfile != null
            ? SharedProfileMessageCard(
                profile: message.sharedProfile!,
                isMine: isMine,
                sharerName: message.senderName,
                onTap: () => _openSharedProfile(context, message),
              )
            : Text(
                message.content,
                style: QeranTypography.body.copyWith(
                  color: textColor,
                  height: 1.4,
                ),
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
    final children = <Widget>[
      Text(time, style: QeranTypography.caption),
    ];
    if (isMine) {
      switch (message.status) {
        case MessageSendStatus.sending:
          children.add(QeranSpacing.hs4);
          children.add(Text(
            LocaleKeys.chat_message_status_sending.t(context),
            style: QeranTypography.caption,
          ));
        case MessageSendStatus.failed:
          children.add(QeranSpacing.hs4);
          children.add(Text(
            LocaleKeys.chat_message_status_failed.t(context),
            style: QeranTypography.caption
                .copyWith(color: QeranColors.danger),
          ));
        case MessageSendStatus.sent:
          if (showReadReceipt && message.isRead) {
            children.add(QeranSpacing.hs4);
            children.add(Text(
              LocaleKeys.chat_message_read_label.t(context),
              style: QeranTypography.caption.copyWith(
                color: QeranColors.wine.withValues(alpha: 0.7),
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
