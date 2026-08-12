import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/enum/snakebar_tybe.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../../../../generated/locale_keys.g.dart';

/// The matchmaker's "Your referral code" card on the account screen. Shows the
/// backend-issued [code], with tap/press to copy (+ a "copied" toast) and a
/// system Share button. Rendered only when a code exists (the caller hides it
/// otherwise — we never fabricate a placeholder for an absent code).
class ReferralShareCard extends StatelessWidget {
  const ReferralShareCard({super.key, required this.code});

  final String code;

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
    AppSnackBar.show(
      context,
      message: LocaleKeys.matchmaker_referral_copied_toast.t(context),
      type: SnackBarType.success,
    );
  }

  void _share(BuildContext context) => SharePlus.instance.share(
    ShareParams(
      text: LocaleKeys.matchmaker_referral_share_message.t(
        context,
        namedArgs: {'code': code},
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return QeranCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.matchmaker_referral_card_title.t(context),
            style: QeranTypography.subtitle.copyWith(
              color: QeranColors.inkStrong,
            ),
          ),
          QeranSpacing.vs12,
          _CodeBox(code: code, onCopy: () => _copy(context)),
          QeranSpacing.vs8,
          Text(
            LocaleKeys.matchmaker_referral_card_hint.t(context),
            style: QeranTypography.bodySm.copyWith(color: QeranColors.inkMuted),
          ),
          QeranSpacing.vs16,
          QeranButton(
            label: LocaleKeys.matchmaker_referral_share_cta.t(context),
            variant: QeranButtonVariant.primaryGold,
            leadingIcon: Icons.ios_share_rounded,
            onPressed: () => _share(context),
          ),
        ],
      ),
    );
  }
}

/// The code on a gold-tinted pill; the whole box (and the trailing icon) copies.
class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.code, required this.onCopy});

  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: QeranRadii.controlR,
      child: InkWell(
        onTap: onCopy,
        borderRadius: QeranRadii.controlR,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: QeranSpacing.s16,
            vertical: QeranSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: QeranColors.gold12,
            borderRadius: QeranRadii.controlR,
            border: Border.all(color: QeranColors.gold40),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  code,
                  textDirection: TextDirection.ltr,
                  style: QeranTypography.numeric.copyWith(
                    fontSize: 18,
                    color: QeranColors.wine,
                  ),
                ),
              ),
              QeranSpacing.hs8,
              const Icon(
                Icons.content_copy_rounded,
                size: 20,
                color: QeranColors.goldDeep,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
