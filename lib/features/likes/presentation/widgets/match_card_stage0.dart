import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
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
/// * `null` (no request yet) → [طلب تبادل الصور] (gold) + [أرسل استفساراتك]
///   (wine).
/// * `requestedByMe` (initiator waiting) → status + countdown, no buttons.
/// * `canAccept/canReject` (responder) → countdown + [قبول الطلب] (gold) +
///   [أرسل استفساراتك] (wine) + a subtle reject link.
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

    return MatchCardScaffold(
      avatar: LikeBlurredImage(url: image?.url, blur: image?.isBlurred ?? true),
      name: card.otherUserName,
      statusIcon: _statusIcon(pending, canRespond),
      statusText: _statusText(context, pending, canRespond),
      statusColor: QeranColors.goldDeep,
      topChip: secs == null
          ? null
          : PhotoExchangeCountdownChip(
              initialSeconds: secs,
              onExpired: onPendingExpiredLocally,
            ),
      footer: _footer(context, pending, canRespond),
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

  Widget? _footer(
    BuildContext context,
    PhotoExchangePending? pending,
    bool canRespond,
  ) {
    // Initiator waiting → no buttons (only the countdown chip).
    if (pending != null && !canRespond) return null;

    if (pending == null) {
      // No request yet (initiator) → request (gold) + inquiry (wine).
      return _TwoButtonRow(
        actionLabel:
            LocaleKeys.likes_matches_stage_waiting_photos_cta.t(context),
        actionOnTap: onRequestPhotoExchange,
        actionLoading: isRequestingPhotoExchange,
        inquiryLabel: LocaleKeys.likes_matches_inquiry_cta.t(context),
        inquiryOnTap: onContactMatchmaker,
      );
    }

    // Responder → accept (gold) + inquiry (wine); subtle reject below.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _TwoButtonRow(
          actionLabel:
              LocaleKeys.likes_matches_photo_exchange_action_accept.t(context),
          actionOnTap: pending.canAccept ? onAcceptPhotoExchange : null,
          actionLoading: isAcceptingPhotoExchange,
          inquiryLabel: LocaleKeys.likes_matches_inquiry_cta.t(context),
          inquiryOnTap: onContactMatchmaker,
        ),
        const SizedBox(height: QeranSpacing.s4),
        Center(
          child: QeranButton(
            label: LocaleKeys.likes_matches_photo_exchange_action_reject
                .t(context),
            onPressed: pending.canReject ? onRejectPhotoExchange : null,
            variant: QeranButtonVariant.ghost,
            size: QeranButtonSize.xs,
            fullWidth: false,
            loading: isRejectingPhotoExchange,
          ),
        ),
      ],
    );
  }
}

/// Two stage CTAs — gold action (leading) + wine inquiry (trailing). The
/// inquiry gets the wider flex so the long "أرسل استفساراتك للخطّابة"
/// label stays on one line; both use the compact [QeranButtonSize.xs].
class _TwoButtonRow extends StatelessWidget {
  final String actionLabel;
  final VoidCallback? actionOnTap;
  final bool actionLoading;
  final String inquiryLabel;
  final VoidCallback? inquiryOnTap;

  const _TwoButtonRow({
    required this.actionLabel,
    required this.actionOnTap,
    required this.actionLoading,
    required this.inquiryLabel,
    required this.inquiryOnTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: QeranButton(
            label: actionLabel,
            onPressed: actionOnTap,
            variant: QeranButtonVariant.primaryGold,
            size: QeranButtonSize.xs,
            loading: actionLoading,
          ),
        ),
        QeranSpacing.hs8,
        Expanded(
          flex: 3,
          child: QeranButton(
            label: inquiryLabel,
            onPressed: inquiryOnTap,
            variant: QeranButtonVariant.primaryWine,
            size: QeranButtonSize.xs,
          ),
        ),
      ],
    );
  }
}
