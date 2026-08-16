import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_card.dart';
import '../../domain/entities/photo_exchange_pending.dart';
import 'match_card_avatar.dart';
import 'match_card_scaffold.dart';
import 'photo_exchange_countdown_chip.dart';

/// Stage 0 — WaitingForPhotoExchange. Three sub-states off
/// `pendingPhotoExchange`:
/// * `null` (no request yet) → [طلب تبادل الصور] (primaryWine) + [أرسل استفساراتك] (ghost).
/// * `requestedByMe` (initiator waiting) → status + countdown, no actions.
/// * `canAccept/canReject` (responder) → countdown + [قبول الطلب] (primaryWine) +
///   [أرسل استفساراتك] (ghost) + [رفض] (ghost).
class MatchCardStage0 extends StatelessWidget {
  final MatchCard card;
  final VoidCallback? onRequestPhotoExchange;
  final bool isRequestingPhotoExchange;
  final VoidCallback? onAcceptPhotoExchange;
  final VoidCallback? onRejectPhotoExchange;
  final bool isAcceptingPhotoExchange;
  final bool isRejectingPhotoExchange;
  final VoidCallback? onContactMatchmaker;
  final bool isInquirySending;
  final bool isInquirySent;

  const MatchCardStage0({
    super.key,
    required this.card,
    required this.onRequestPhotoExchange,
    required this.isRequestingPhotoExchange,
    required this.onAcceptPhotoExchange,
    required this.onRejectPhotoExchange,
    required this.isAcceptingPhotoExchange,
    required this.isRejectingPhotoExchange,
    required this.onContactMatchmaker,
    this.isInquirySending = false,
    this.isInquirySent = false,
  });

  @override
  Widget build(BuildContext context) {
    final image = card.primaryImage;
    final pending = card.pendingPhotoExchange;
    // Presence of the block — and of its expiresAt — proves nothing here:
    // /api/matches keeps returning `pendingPhotoExchange` with a real
    // timestamp after the deadline has passed (confirmed with Tariq). The
    // state comes from `status` plus the comparison, never from the field
    // being non-null.
    final live = pending?.isAwaitingResponse ?? false;
    final secs = live ? pending?.remainingSeconds : null;
    final canRespond = live && (pending!.canAccept || pending.canReject);

    // Map header data
    final avatarWidget = MatchCardAvatar(
      url: image?.url,
      blur: image?.isBlurred ?? true,
      blurredUrl: image?.blurredUrl,
      blurredThumbnailUrl: image?.blurredThumbnailUrl,
    );
    final nameText = card.otherUserName;
    final statusIconData = _statusIcon(pending, canRespond, live);
    final statusTextString = _statusText(context, pending, canRespond, live);
    final statusColor = QeranColors.goldDeep;
    // No onExpired: hitting zero swaps the chip to "expired" and stops. It
    // deliberately does NOT refetch the list — a row rearranging itself under
    // a thumb that is mid-scroll is worse than a stale row the user can
    // pull-to-refresh.
    final topChipWidget = secs == null
        ? null
        : PhotoExchangeCountdownChip(initialSeconds: secs);

    // Map footer actions
    String? primaryLabel;
    VoidCallback? onPrimaryPressed;
    bool primaryLoading = false;
    Widget? primaryOverride;
    List<Widget>? secondaryActions;

    if (pending == null) {
      // No request yet -> Request (gold primary) + Inquiry (ghost footer)
      primaryLabel = LocaleKeys.likes_matches_stage_waiting_photos_cta.t(
        context,
      );
      onPrimaryPressed = onRequestPhotoExchange;
      primaryLoading = isRequestingPhotoExchange;
      secondaryActions = [_inquiryButton(context)];
    } else if (canRespond) {
      // Responder -> [Reject (outline)] + [Accept (gold)] side by side, with
      // Inquiry as a ghost footer below.
      primaryOverride = Row(
        children: [
          Expanded(
            child: QeranButton(
              label: LocaleKeys.likes_matches_photo_exchange_action_reject.t(
                context,
              ),
              onPressed: pending.canReject ? onRejectPhotoExchange : null,
              variant: QeranButtonVariant.secondary,
              size: QeranButtonSize.xs,
              loading: isRejectingPhotoExchange,
            ),
          ),
          const SizedBox(width: QeranSpacing.s8),
          Expanded(
            child: QeranButton(
              label: LocaleKeys.likes_matches_photo_exchange_action_accept.t(
                context,
              ),
              onPressed: pending.canAccept ? onAcceptPhotoExchange : null,
              variant: QeranButtonVariant.primary,
              size: QeranButtonSize.xs,
              loading: isAcceptingPhotoExchange,
            ),
          ),
        ],
      );
      secondaryActions = [_inquiryButton(context)];
    }

    return MatchCardScaffold(
      avatar: avatarWidget,
      name: nameText,
      statusIcon: statusIconData,
      statusText: statusTextString,
      statusColor: statusColor,
      topChip: topChipWidget,
      primaryLabel: primaryLabel,
      onPrimaryPressed: onPrimaryPressed,
      primaryLoading: primaryLoading,
      primaryVariant: QeranButtonVariant.primary,
      primaryOverride: primaryOverride,
      secondaryActions: secondaryActions,
    );
  }

  /// Strong, full-width inquiry action. This must read as a real button in
  /// the compatibility list, not as a low-emphasis text link.
  Widget _inquiryButton(BuildContext context) {
    return QeranButton(
      label:
          (isInquirySent
                  ? LocaleKeys.likes_matches_inquiry_sent
                  : LocaleKeys.likes_matches_inquiry_cta)
              .t(context),
      onPressed: isInquirySent ? null : onContactMatchmaker,
      variant: QeranButtonVariant.primaryWine,
      size: QeranButtonSize.xs,
      loading: isInquirySending,
    );
  }

  IconData _statusIcon(
    PhotoExchangePending? pending,
    bool canRespond,
    bool live,
  ) {
    if (pending != null && !live) return Icons.timer_off_rounded;
    if (pending != null && !canRespond) return Icons.access_time_rounded;
    return Icons.lock_outline_rounded;
  }

  /// [live] is checked FIRST. A lapsed request still arrives as a Pending
  /// block, and reading it as "awaiting a reply" told the member to keep
  /// waiting for an answer that can no longer come — the countdown vanished
  /// but the copy still said pending. It now says the window closed.
  String _statusText(
    BuildContext context,
    PhotoExchangePending? pending,
    bool canRespond,
    bool live,
  ) {
    if (pending != null && !live) {
      return LocaleKeys.likes_status_expired.t(context);
    }
    if (pending != null && !canRespond) {
      return LocaleKeys.likes_matches_stage_waiting_photos_pending.t(context);
    }
    return LocaleKeys.likes_matches_stage_waiting_photos_title.t(context);
  }
}
