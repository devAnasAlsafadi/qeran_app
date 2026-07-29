import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

/// Card-body section: header (server-supplied Arabic label) + free text.
class DiscoveryAboutMe extends StatelessWidget {
  final String header;
  final String text;

  /// Max number of lines for the body text. `null` shows the full text
  /// (the main card scrolls internally); a small value (e.g. 2) truncates
  /// with ellipsis for the peek preview.
  final int? maxLines;

  const DiscoveryAboutMe({
    super.key,
    required this.header,
    required this.text,
    this.maxLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.person_outline_rounded,
              size: 16,
              color: QeranColors.wine,
            ),
            const SizedBox(width: QeranSpacing.s6),
            Text(header, style: QeranTypography.label),
          ],
        ),
        const SizedBox(height: QeranSpacing.s8),
        Text(
          text,
          style: QeranTypography.body,
          maxLines: maxLines,
          // Only ellipsize when there is a line budget to exceed. An ellipsis
          // with a null maxLines does NOT mean "unlimited lines, then …" — it
          // is applied to the first line that outgrows the width, which cut
          // the whole paragraph down to one line. Same rule as
          // `AboutMeSection` / `AboutPartnerSection` on the full profile.
          overflow: maxLines == null
              ? TextOverflow.clip
              : TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
