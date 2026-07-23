import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../core/design_system/tokens/qeran_typography.dart';

/// Icon-chip accent for a [SettingsRow]. `wine` is the default; `gold` is the
/// premium/subscription row; `danger` is destructive (delete/deactivate).
enum SettingsRowAccent { wine, gold, danger }

/// One tappable row inside a settings card — leading tinted icon chip + title
/// (+ optional subtitle) + optional trailing widget + an auto-mirroring
/// chevron. Shared by both roles (it superseded the duplicated user
/// `_SettingsRow` and `MatchmakerSettingsRow`).
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.accent = SettingsRowAccent.wine,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final SettingsRowAccent accent;

  @override
  Widget build(BuildContext context) {
    final destructive = accent == SettingsRowAccent.danger;
    final iconColor = switch (accent) {
      SettingsRowAccent.wine => QeranColors.wine,
      SettingsRowAccent.gold => QeranColors.goldDeep,
      SettingsRowAccent.danger => QeranColors.danger,
    };
    final chipColor = switch (accent) {
      SettingsRowAccent.wine => QeranColors.wine06,
      SettingsRowAccent.gold => QeranColors.gold12,
      SettingsRowAccent.danger => QeranColors.danger12,
    };
    final titleColor = onTap == null
        ? QeranColors.inkMuted
        : destructive
        ? QeranColors.danger
        : QeranColors.wine;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        splashColor: QeranColors.creamSurface,
        highlightColor: QeranColors.creamSurface.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: chipColor,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: iconColor),
              ),
              QeranSpacing.hs12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: QeranTypography.body.copyWith(color: titleColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      QeranSpacing.vs4,
                      Text(
                        subtitle!,
                        style: QeranTypography.caption.copyWith(
                          color: QeranColors.inkMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[QeranSpacing.hs8, trailing!],
              if (onTap != null) ...[
                QeranSpacing.hs8,
                // `chevron_right_rounded` auto-mirrors under the ambient
                // Directionality: points inward in RTL, right in LTR.
                const Icon(
                  Icons.chevron_right_rounded,
                  color: QeranColors.wine,
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Hairline divider between [SettingsRow]s, indented past the 40dp leading
/// chip + gap so the line aligns under the row title, not the icon.
class SettingsRowDivider extends StatelessWidget {
  const SettingsRowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsetsDirectional.only(start: 60, end: 16),
      child: SizedBox(height: 1, child: ColoredBox(color: QeranColors.divider)),
    );
  }
}
