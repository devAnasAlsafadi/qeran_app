import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/presentation/widgets/community_network_image.dart';

import '../../../../core/shipped_fonts_rig.dart';
import '../../../../core/shipped_strings_rig.dart';

/// A8 at its own size (run 6): the failed photo's message and retry are never
/// scaled down, and the smallest frame that shows them — a post's 16:9 photo
/// on a 320 phone, 264 × 148 — holds them whole.
void main() {
  setUpAll(() async {
    await initShippedStrings();
    await loadShippedFonts();
  });

  for (final lang in const ['ar', 'en']) {
    for (final onWine in const [false, true]) {
      testWidgets('fits the smallest frame, unscaled [$lang, onWine $onWine]', (
        tester,
      ) async {
        await pumpOnPhone(
          tester,
          lang,
          SizedBox(
            width: 264,
            height: 148,
            child: CommunityImageFailed(onRetry: () {}, onWine: onWine),
          ),
          width: 320,
          localized: true,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(FittedBox), findsNothing);
        expect(isCut(tester, shipped(lang, 'community.retry')), isFalse);
      });
    }
  }
}
