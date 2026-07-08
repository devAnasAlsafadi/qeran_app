import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Locked variant — the server redacted the identity because the user
/// isn't subscribed. The whole [QeranCard] is the tap target (routes to
/// packages), so this only paints the redacted row: a lock-glyph avatar on
/// the leading edge, a **redacted-name bar** where the name would be, the
/// "unlock" subtitle, and a trailing disclosure chevron.
class LikeCardLocked extends StatelessWidget {
  const LikeCardLocked({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _LockAvatar(),
        QeranSpacing.hs12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Redacted name — the identity stays hidden until the user
              // subscribes, so the name slot is a soft placeholder bar.
              Container(
                width: 128,
                height: 13,
                decoration: const BoxDecoration(
                  color: QeranColors.wine12,
                  borderRadius: QeranRadii.pill,
                ),
              ),
              const SizedBox(height: QeranSpacing.s12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    size: 14,
                    color: QeranColors.wine,
                  ),
                  QeranSpacing.hs4,
                  Flexible(
                    child: Text(
                      LocaleKeys.likes_locked_card_subtitle.t(context),
                      textAlign: TextAlign.start,
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
            ],
          ),
        ),
        QeranSpacing.hs8,
        // Disclosure affordance — auto-mirrors with the locale (right in LTR,
        // left in RTL); gold ties it to the premium-unlock accent.
        const Icon(Icons.chevron_right_rounded, color: QeranColors.gold),
      ],
    );
  }
}

class _LockAvatar extends StatelessWidget {
  const _LockAvatar();

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        width: 64,
        height: 64,
        color: QeranColors.wine08,
        alignment: Alignment.center,
        child: const Icon(Icons.lock_rounded, color: QeranColors.wine),
      ),
    );
  }
}
