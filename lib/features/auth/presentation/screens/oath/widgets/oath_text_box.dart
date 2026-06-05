import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Premium oath card — warm cream→beige gradient surface, soft burgundy
/// shadow, basmala flanked by tiny diamond ornaments, hair-line divider,
/// and the oath body in a calm reading rhythm.
class OathTextBox extends StatelessWidget {
  const OathTextBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(QeranSpacing.s24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [QeranColors.paper, QeranColors.creamSurface],
        ),
        borderRadius: QeranRadii.panelR,
        border: Border.all(
          color: QeranColors.wine.withValues(alpha: 0.25),
        ),
        boxShadow: QeranShadows.e3,
      ),
      child: Column(
        children: [
          const _BasmalaRow(),
          QeranSpacing.vs16,
          _Divider(),
          QeranSpacing.vs16,
          Text(
            LocaleKeys.auth_oath_text.t(context),
            textAlign: TextAlign.center,
            style: QeranTypography.body.copyWith(
              color: QeranColors.inkStrong,
              height: 1.9,
              fontSize: 16,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _BasmalaRow extends StatelessWidget {
  const _BasmalaRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.diamond_outlined,
          size: 10,
          color: QeranColors.wine,
        ),
        QeranSpacing.hs8,
        Flexible(
          child: Text(
            LocaleKeys.auth_oath_basmala.t(context),
            textAlign: TextAlign.center,
            style: QeranTypography.headline.copyWith(
              color: QeranColors.wine,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        QeranSpacing.hs8,
        const Icon(
          Icons.diamond_outlined,
          size: 10,
          color: QeranColors.wine,
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            QeranColors.wine.withValues(alpha: 0.0),
            QeranColors.wine.withValues(alpha: 0.25),
            QeranColors.wine.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
