import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/like_request_card.dart';
import '../../domain/entities/like_request_status.dart';

/// Status line under the name — a small icon + label whose hue follows
/// the like's state: deep-gold "waiting" for pending (Qeran's pending
/// accent), wine for accepted (success wears wine/gold, never green),
/// muted ink for rejected / expired.
class LikeCardStatus extends StatelessWidget {
  final LikeRequestCard card;
  const LikeCardStatus({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final (icon, key, color) = _visual(card.status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        QeranSpacing.hs4,
        Flexible(
          child: Text(
            key.t(context),
            textAlign: TextAlign.start,
            style: QeranTypography.bodySm.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  (IconData, String, Color) _visual(LikeRequestStatus status) {
    switch (status) {
      case LikeRequestStatus.pending:
        return (
          Icons.access_time_rounded,
          LocaleKeys.likes_status_pending,
          QeranColors.goldDeep,
        );
      case LikeRequestStatus.accepted:
        return (
          Icons.favorite_rounded,
          LocaleKeys.likes_status_accepted,
          QeranColors.wine,
        );
      case LikeRequestStatus.rejected:
        return (
          Icons.close_rounded,
          LocaleKeys.likes_status_rejected,
          QeranColors.inkMuted,
        );
      case LikeRequestStatus.expired:
      case LikeRequestStatus.unknown:
        return (
          Icons.hourglass_disabled_rounded,
          LocaleKeys.likes_status_expired,
          QeranColors.inkMuted,
        );
    }
  }
}
