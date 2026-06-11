import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_card.dart';

import '../../domain/entities/like_request_card.dart';
import '../../domain/entities/like_request_status.dart';
import 'like_card_actions.dart';
import 'like_card_avatar.dart';
import 'like_card_countdown_chip.dart';
import 'like_card_locked.dart';
import 'like_card_status.dart';

/// One row in the Likes / Interests list.
///
/// Figma layout, mirrored automatically by locale: avatar on the leading
/// edge, a name + status block in the middle, and — for pending rows — a
/// trailing column holding the live countdown chip above the accept /
/// reject buttons (incoming only).
///
/// Three variants share the same [QeranCard] shell:
/// * **Locked** — identity redacted; tap-anywhere routes to packages.
/// * **Pending** — name + soft-blurred avatar + deep-gold "waiting"
///   status + live countdown; (incoming only) accept / reject buttons.
/// * **Archived** — name + image + muted status (accepted / rejected /
///   expired); no actions.
class LikeUserCard extends StatelessWidget {
  final LikeRequestCard card;

  /// Fired when the user taps Accept on an incoming pending row. Wired
  /// to `LikesCubit.acceptLike(card.likeRequestId)`.
  final VoidCallback? onAccept;

  /// Fired when the user taps Reject. Wired to
  /// `LikesCubit.rejectLike(card.likeRequestId)`.
  final VoidCallback? onReject;

  /// Fired when the user taps a locked card. The screen pushes Packages.
  final VoidCallback? onUnlock;

  /// Fired when the user taps a non-locked row. Pushes the reusable Full
  /// Profile Details screen. Null disables the tap.
  final VoidCallback? onOpenProfile;

  /// True while the accept call is in flight — the heart shows a loader
  /// and both circular buttons disable (rapid taps must not stack).
  final bool isAccepting;

  /// True while the reject call is in flight.
  final bool isRejecting;

  const LikeUserCard({
    super.key,
    required this.card,
    this.onAccept,
    this.onReject,
    this.onUnlock,
    this.onOpenProfile,
    this.isAccepting = false,
    this.isRejecting = false,
  });

  @override
  Widget build(BuildContext context) {
    return QeranCard(
      margin: const EdgeInsets.only(bottom: QeranSpacing.s12),
      padding: const EdgeInsets.all(QeranSpacing.s16),
      onTap: card.isLocked ? onUnlock : onOpenProfile,
      child: card.isLocked
          ? const LikeCardLocked()
          : _VisibleContent(
              card: card,
              onAccept: onAccept,
              onReject: onReject,
              isAccepting: isAccepting,
              isRejecting: isRejecting,
            ),
    );
  }
}

class _VisibleContent extends StatelessWidget {
  final LikeRequestCard card;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool isAccepting;
  final bool isRejecting;

  const _VisibleContent({
    required this.card,
    required this.onAccept,
    required this.onReject,
    required this.isAccepting,
    required this.isRejecting,
  });

  bool get _isPending => card.status == LikeRequestStatus.pending;

  @override
  Widget build(BuildContext context) {
    final showTimer = _isPending && card.remainingSeconds != null;
    final showActions = _isPending && (card.canAccept || card.canReject);

    Widget? trailing;
    if (showTimer || showActions) {
      trailing = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTimer)
            LikeCountdownChip(initialSeconds: card.remainingSeconds!),
          if (showTimer && showActions) QeranSpacing.vs12,
          if (showActions)
            LikeCardActions(
              onAccept: onAccept,
              onReject: onReject,
              isAccepting: isAccepting,
              isRejecting: isRejecting,
            ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LikeCardAvatar(image: card.profileImage),
        QeranSpacing.hs12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                card.name,
                textAlign: TextAlign.start,
                style:
                    QeranTypography.subtitle.copyWith(color: QeranColors.wine),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: QeranSpacing.s6),
              LikeCardStatus(card: card),
            ],
          ),
        ),
        if (trailing != null) ...[
          QeranSpacing.hs12,
          trailing,
        ],
      ],
    );
  }
}
