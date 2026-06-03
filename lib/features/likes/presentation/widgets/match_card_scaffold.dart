import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

/// Shared body for every Matches-tab card so all stages read with one
/// padding + alignment rhythm — only the stage-specific [footer] (CTA /
/// button rows) and the optional [topChip] (pending countdown) change.
///
/// Layout mirrors automatically by locale: the avatar sits on the
/// leading edge; the trailing column carries an optional countdown chip,
/// the name, and a status line. Token gaps: countdown→name = s8,
/// name→status = s6, status→[footer] = s8.
class MatchCardScaffold extends StatelessWidget {
  final Widget avatar;
  final String name;
  final IconData statusIcon;
  final String statusText;
  final Color statusColor;

  /// Optional pending-countdown chip, shown on its own line above the
  /// name (leading).
  final Widget? topChip;

  /// Optional stage action(s) below the header.
  final Widget? footer;

  const MatchCardScaffold({
    super.key,
    required this.avatar,
    required this.name,
    required this.statusIcon,
    required this.statusText,
    required this.statusColor,
    this.topChip,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            avatar,
            QeranSpacing.hs12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (topChip != null) ...[
                    topChip!,
                    const SizedBox(height: QeranSpacing.s8),
                  ],
                  Text(
                    name,
                    textAlign: TextAlign.start,
                    style: QeranTypography.subtitle
                        .copyWith(color: QeranColors.wine),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: QeranSpacing.s4),
                  _StatusLine(
                    icon: statusIcon,
                    text: statusText,
                    color: statusColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (footer != null) ...[
          const SizedBox(height: QeranSpacing.s8),
          footer!,
        ],
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _StatusLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        QeranSpacing.hs4,
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.start,
            style: QeranTypography.bodySm.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
