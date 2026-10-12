import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/features/settings/presentation/widgets/settings_row.dart';

import '../../../../core/shipped_fonts_rig.dart';

/// Profile → «اشتراكي» with no active plan: its subtitle, beside the «ترقية»
/// chip, takes two lines at 360 rather than being cut (run 6).
void main() {
  setUpAll(loadShippedFonts);

  for (final lang in const ['ar', 'en']) {
    testWidgets('the subscription row\'s subtitle is never cut [$lang]', (
      tester,
    ) async {
      final subtitle = shipped(
        lang,
        'subscriptions.subscription_row_subtitle_with_restore',
      );
      await pumpOnPhone(
        tester,
        lang,
        // The profile's settings list pads its card by s16.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SettingsRow(
            icon: Icons.workspace_premium_rounded,
            title: shipped(lang, 'subscriptions.status_my_subscription'),
            subtitle: subtitle,
            trailing: QeranChip(
              label: shipped(lang, 'settings.upgrade'),
              variant: QeranChipVariant.interest,
              compact: true,
            ),
            onTap: () {},
          ),
        ),
      );

      expect(isCut(tester, subtitle), isFalse);
    });
  }
}
