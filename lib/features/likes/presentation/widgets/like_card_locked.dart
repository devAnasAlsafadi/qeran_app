import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Locked variant — the server redacted the identity because the user
/// isn't subscribed. The whole [QeranCard] is the tap target (routes to
/// packages), so this only paints the redacted row: a lock-glyph avatar
/// on the leading edge + the "unlock" title and subtitle.
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
              Text(
                LocaleKeys.likes_locked_card_title.t(context),
                textAlign: TextAlign.start,
                style: QeranTypography.title.copyWith(color: QeranColors.wine),
              ),
              const SizedBox(height: QeranSpacing.s8),
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
