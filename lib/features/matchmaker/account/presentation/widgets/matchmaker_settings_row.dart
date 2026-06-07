import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';

/// One tappable row inside the account settings card — leading tinted circle
/// icon + title (+ optional subtitle) + optional trailing + auto-mirroring
/// chevron. Mirrors the user-app settings row in our identity.
class MatchmakerSettingsRow extends StatelessWidget {
  const MatchmakerSettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? QeranColors.danger : QeranColors.wine;
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: QeranColors.creamSurface,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: accent),
              ),
              QeranSpacing.hs12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: QeranTypography.body.copyWith(color: accent),
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
              QeranSpacing.hs8,
              const Icon(
                Icons.chevron_right_rounded,
                color: QeranColors.wine,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hairline divider between rows, indented past the leading circle so it aligns
/// under the title.
class MatchmakerSettingsRowDivider extends StatelessWidget {
  const MatchmakerSettingsRowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsetsDirectional.only(start: 60, end: 16),
      child: SizedBox(
        height: 1,
        child: ColoredBox(color: QeranColors.divider),
      ),
    );
  }
}
