import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

/// Card-body section: header (server-supplied Arabic label) + free text.
class DiscoveryAboutMe extends StatelessWidget {
  final String header;
  final String text;

  /// Max number of lines for the body text. Defaults to 3 so a typical
  /// long bio truncates with ellipsis on the card; the details sheet
  /// shows the full text.
  final int maxLines;

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
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
