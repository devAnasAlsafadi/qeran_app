import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Premium wine strip that sits above the incoming list when the
/// server reports `requiresSubscription: true`. Tapping it pushes the
/// existing Packages route — never invents a paywall sheet.
class LikesLockedBanner extends StatelessWidget {
  final VoidCallback onSubscribe;
  const LikesLockedBanner({super.key, required this.onSubscribe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        0,
        QeranSpacing.s20,
        QeranSpacing.s12,
      ),
      child: Material(
        color: QeranColors.wine,
        borderRadius: QeranRadii.cardR,
        child: InkWell(
          onTap: onSubscribe,
          borderRadius: QeranRadii.cardR,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: QeranSpacing.s16,
              vertical: QeranSpacing.s12,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: QeranColors.gold20,
                    border: Border.all(color: QeranColors.gold, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.lock_rounded,
                    color: QeranColors.gold,
                    size: 20,
                  ),
                ),
                QeranSpacing.hs12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleKeys.likes_locked_title.t(context),
                        style: QeranTypography.subtitle
                            .copyWith(color: QeranColors.paper),
                      ),
                      QeranSpacing.vs4,
                      Text(
                        LocaleKeys.likes_locked_subtitle.t(context),
                        style: QeranTypography.caption
                            .copyWith(color: QeranColors.gold),
                      ),
                    ],
                  ),
                ),
                QeranSpacing.hs8,
                // chevron_right_rounded auto-mirrors with the locale:
                // points right in LTR, left in RTL — a forward/disclosure
                // affordance consistent with the settings rows.
                const Icon(
                  Icons.chevron_right_rounded,
                  color: QeranColors.gold,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
