import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// A soft cream pill on a stage-1/2 match card surfacing the matchmaker's
/// current formal-request status — "حالة الخطّابة: {status}".
///
/// [status] is the backend's server-localized `FormalRequest` status name
/// (picked by locale upstream and rendered verbatim — no `.tr()` on it). The
/// caller omits the pill entirely when no status is available, so cards with an
/// empty status keep their static subtitle.
class MatchMatchmakerStatusPill extends StatelessWidget {
  final String status;
  const MatchMatchmakerStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: QeranSpacing.s12,
          vertical: QeranSpacing.s6,
        ),
        decoration: BoxDecoration(
          color: QeranColors.creamSurface,
          borderRadius: QeranRadii.pill,
          border: Border.all(color: QeranColors.gold40),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.support_agent_rounded,
              size: 14,
              color: QeranColors.goldDeep,
            ),
            QeranSpacing.hs4,
            Flexible(
              child: Text(
                context.tr(
                  LocaleKeys.likes_matches_matchmaker_status,
                  namedArgs: {'status': status},
                ),
                style: QeranTypography.bodySm.copyWith(
                  color: QeranColors.wine,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
