import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../domain/entities/community_guidelines.dart';
import '../../formatting/guideline_icons.dart';

/// The server's guidelines (D39) in the app's language: the intro, then
/// each rule under its icon (W2). It scrolls above the pinned choice.
class GuidelinesText extends StatelessWidget {
  const GuidelinesText({super.key, required this.guidelines});

  final CommunityGuidelines guidelines;

  static const _padding = EdgeInsetsDirectional.fromSTEB(
    QeranSpacing.s20,
    QeranSpacing.s12,
    QeranSpacing.s20,
    QeranSpacing.s24,
  );

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final intro = isAr ? guidelines.introAr : guidelines.introEn;
    return ListView(
      padding: _padding,
      children: [
        if (intro.trim().isNotEmpty)
          Text(
            intro,
            style: QeranTypography.body.copyWith(
              height: QeranTypography.readingLineHeight,
            ),
          ),
        for (final section in guidelines.sections) ...[
          QeranSpacing.vs16,
          _SectionRow(section: section, isAr: isAr),
        ],
      ],
    );
  }
}

/// One rule: its icon on a cream disc, the title, then what it means.
class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.section, required this.isAr});

  final CommunityGuidelineSection section;
  final bool isAr;

  static const double _disc = 40;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _disc,
          height: _disc,
          decoration: const BoxDecoration(
            color: QeranColors.creamSurface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            guidelineIcon(section.iconName),
            size: 20,
            color: QeranColors.wine,
          ),
        ),
        QeranSpacing.hs12,
        Expanded(child: _words()),
      ],
    );
  }

  Widget _words() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        isAr ? section.titleAr : section.titleEn,
        style: QeranTypography.subtitle,
      ),
      const SizedBox(height: QeranSpacing.s2),
      Text(
        isAr ? section.bodyAr : section.bodyEn,
        style: QeranTypography.bodySm.copyWith(color: QeranColors.inkMuted),
      ),
    ],
  );
}
