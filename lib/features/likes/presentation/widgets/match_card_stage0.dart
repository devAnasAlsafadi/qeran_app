import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_card.dart';
import '../../domain/entities/photo_exchange_pending.dart';
import 'like_blurred_image.dart';
import 'photo_exchange_action_row.dart';
import 'photo_exchange_countdown_chip.dart';

/// Stage 0 — WaitingForPhotoExchange.
///
/// * `pendingPhotoExchange == null` → primary CTA "Request photo
///   exchange".
/// * `requestedByMe == true` → muted "Awaiting their response" pill
///   + countdown.
/// * `canAccept && canReject` → Accept/Reject circular buttons
///   + countdown (responder path).
/// * Otherwise → defensive waiting pill + countdown.
class MatchCardStage0 extends StatelessWidget {
  final MatchCard card;
  final VoidCallback? onRequestPhotoExchange;
  final bool isRequestingPhotoExchange;
  final VoidCallback? onAcceptPhotoExchange;
  final VoidCallback? onRejectPhotoExchange;
  final bool isAcceptingPhotoExchange;
  final bool isRejectingPhotoExchange;
  final VoidCallback? onPendingExpiredLocally;

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
  });

  @override
  Widget build(BuildContext context) {
    final pending = card.pendingPhotoExchange;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(card: card),
        const SizedBox(height: AppDimens.p16),
        if (pending == null)
          _RequestCta(
            isInFlight: isRequestingPhotoExchange,
            onTap: onRequestPhotoExchange,
          )
        else
          _PendingFooter(
            pending: pending,
            onAccept: onAcceptPhotoExchange,
            onReject: onRejectPhotoExchange,
            isAccepting: isAcceptingPhotoExchange,
            isRejecting: isRejectingPhotoExchange,
            onExpiredLocally: onPendingExpiredLocally,
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final MatchCard card;
  const _Header({required this.card});

  @override
  Widget build(BuildContext context) {
    final image = card.primaryImage;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.otherUserName,
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimens.p8),
              Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: Color(0xFFB18454),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      LocaleKeys.likes_matches_stage_waiting_photos_title
                          .t(context),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFFB18454),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimens.p12),
        LikeBlurredImage(url: image?.url, blur: true),
      ],
    );
  }
}

class _RequestCta extends StatelessWidget {
  final bool isInFlight;
  final VoidCallback? onTap;
  const _RequestCta({required this.isInFlight, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = isInFlight || onTap == null;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: disabled
            ? AppColors.primary.withValues(alpha: 0.55)
            : AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: isInFlight
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : Text(
                      LocaleKeys.likes_matches_stage_waiting_photos_cta
                          .t(context),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingFooter extends StatelessWidget {
  final PhotoExchangePending pending;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool isAccepting;
  final bool isRejecting;
  final VoidCallback? onExpiredLocally;

  const _PendingFooter({
    required this.pending,
    required this.onAccept,
    required this.onReject,
    required this.isAccepting,
    required this.isRejecting,
    required this.onExpiredLocally,
  });

  @override
  Widget build(BuildContext context) {
    final secs = pending.remainingSeconds;
    // Source-of-truth priority (per product spec):
    //   1. canAccept || canReject → render Accept/Reject buttons.
    //   2. requestedByMe          → render "awaiting their response".
    //   3. otherwise (defensive)  → render same waiting state — receiver
    //      whose action window has closed; the next refresh will move
    //      the row off Stage 0.
    //
    // Previously this gated `&&` on both flags AND on `!requestedByMe`,
    // so a single misaligned flag (or a non-actionable Received row)
    // silently fell through to the waiting state. We now branch on
    // canAccept/canReject alone.
    final canRespond = pending.canAccept || pending.canReject;
    if (canRespond) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (secs != null)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: PhotoExchangeCountdownChip(
                initialSeconds: secs,
                onExpired: onExpiredLocally,
              ),
            ),
          if (secs != null) const SizedBox(height: AppDimens.p12),
          PhotoExchangeActionRow(
            onAccept: pending.canAccept ? onAccept : null,
            onReject: pending.canReject ? onReject : null,
            isAccepting: isAccepting,
            isRejecting: isRejecting,
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            LocaleKeys.likes_matches_stage_waiting_photos_pending.t(context),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (secs != null) ...[
          const SizedBox(width: AppDimens.p8),
          PhotoExchangeCountdownChip(
            initialSeconds: secs,
            onExpired: onExpiredLocally,
          ),
        ],
      ],
    );
  }
}
