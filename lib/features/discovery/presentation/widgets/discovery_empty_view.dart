import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Shown when the deck is empty (`profiles.isEmpty`) or exhausted
/// (`currentIndex >= profiles.length`).
class DiscoveryEmptyView extends StatelessWidget {
  const DiscoveryEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(QeranSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_outline_rounded,
              size: 72,
              color: QeranColors.inkMuted,
            ),
            const SizedBox(height: QeranSpacing.s16),
            Text(
              LocaleKeys.discovery_empty_title.t(context),
              style: QeranTypography.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: QeranSpacing.s8),
            Text(
              LocaleKeys.discovery_empty_subtitle.t(context),
              style: QeranTypography.body.copyWith(color: QeranColors.inkMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
