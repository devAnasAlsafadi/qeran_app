import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_card.dart';
import '../../domain/entities/photo_exchange_pending.dart';
import 'like_blurred_image.dart';
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
  final VoidCallback? onPendingExpiredLocally;
  final VoidCallback? onContactMatchmaker;

  const MatchCardStage0({
    super.key,
    required this.card,
    required this.onRequestPhotoExchange,
    required this.isRequestingPhotoExchange,
    required this.onAcceptPhotoExchange,
    required this.onRejectPhotoExchange,
    required this.isAcceptingPhotoExchange,
    required this.isRejectingPhotoExchange,
    required this.onPendingExpiredLocally,
    required this.onContactMatchmaker,
  });

  @override
  Widget build(BuildContext context) {
    final image = card.primaryImage;
    final pending = card.pendingPhotoExchange;
    final secs = pending?.remainingSeconds;
    final canRespond =
        pending != null && (pending.canAccept || pending.canReject);

    // Map header data
    final avatarWidget = LikeBlurredImage(url: image?.url, blur: image?.isBlurred ?? true);
    final nameText = card.otherUserName;
    final statusIconData = _statusIcon(pending, canRespond);
    final statusTextString = _statusText(context, pending, canRespond);
    final statusColor = QeranColors.goldDeep;
    final topChipWidget = secs == null
        ? null
        : PhotoExchangeCountdownChip(
            initialSeconds: secs,
            onExpired: onPendingExpiredLocally,
          );

    // Map footer actions
    String? primaryLabel;
    VoidCallback? onPrimaryPressed;
    bool primaryLoading = false;
    List<Widget>? secondaryActions;

    if (pending == null) {
      // No request yet -> Request (primary) + Inquiry (secondary)
      primaryLabel = LocaleKeys.likes_matches_stage_waiting_photos_cta.t(context);
      onPrimaryPressed = onRequestPhotoExchange;
      primaryLoading = isRequestingPhotoExchange;
      secondaryActions = [
        QeranButton(
          label: LocaleKeys.likes_matches_inquiry_cta.t(context),
          onPressed: onContactMatchmaker,
          variant: QeranButtonVariant.ghost,
          size: QeranButtonSize.xs,
          fullWidth: false,
        ),
      ];
    } else if (canRespond) {
      // Responder -> Accept (primary) + Inquiry & Decline (secondary)
      primaryLabel = LocaleKeys.likes_matches_photo_exchange_action_accept.t(context);
      onPrimaryPressed = pending.canAccept ? onAcceptPhotoExchange : null;
      primaryLoading = isAcceptingPhotoExchange;
      secondaryActions = [
        QeranButton(
          label: LocaleKeys.likes_matches_inquiry_cta.t(context),
          onPressed: onContactMatchmaker,
          variant: QeranButtonVariant.ghost,
          size: QeranButtonSize.xs,
          fullWidth: false,
        ),
        QeranButton(
          label: LocaleKeys.likes_matches_photo_exchange_action_reject.t(context),
          onPressed: pending.canReject ? onRejectPhotoExchange : null,
          variant: QeranButtonVariant.ghost,
          size: QeranButtonSize.xs,
          fullWidth: false,
          loading: isRejectingPhotoExchange,
        ),
      ];
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
      secondaryActions: secondaryActions,
    );
  }

  IconData _statusIcon(PhotoExchangePending? pending, bool canRespond) {
    if (pending != null && !canRespond) return Icons.access_time_rounded;
    return Icons.lock_outline_rounded;
  }

  String _statusText(
    BuildContext context,
    PhotoExchangePending? pending,
    bool canRespond,
  ) {
    if (pending != null && !canRespond) {
      return LocaleKeys.likes_matches_stage_waiting_photos_pending.t(context);
    }
    return LocaleKeys.likes_matches_stage_waiting_photos_title.t(context);
  }
}
