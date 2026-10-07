import 'package:flutter/material.dart';

import '../../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../generated/locale_keys.g.dart';

/// «على: {the post's start}» with a chevron (E7): opens the post at the
/// reported item (D36). One line; the rest is cut.
class ReportPostLink extends StatelessWidget {
  const ReportPostLink({super.key, required this.snippet, required this.onTap});

  final String snippet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: QeranColors.creamCanvas,
      borderRadius: QeranRadii.controlR,
      child: InkWell(
        onTap: onTap,
        borderRadius: QeranRadii.controlR,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s12),
            child: _content(context),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) => Row(
    children: [
      const Icon(Icons.article_outlined, size: 16, color: QeranColors.inkMuted),
      const SizedBox(width: QeranSpacing.s6),
      Expanded(child: _label(context)),
      const Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: QeranColors.inkMuted,
      ),
    ],
  );

  Widget _label(BuildContext context) => Text(
    LocaleKeys.matchmaker_community_report_on.t(
      context,
      namedArgs: {'snippet': snippet},
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: QeranTypography.caption.copyWith(
      color: QeranColors.inkMuted,
      fontWeight: FontWeight.w600,
    ),
  );
}
