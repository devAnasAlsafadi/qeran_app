import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/effects/ring_motif.dart';
import 'package:qeran/features/likes/presentation/screens/match_success_screen.dart';

import '../../../../core/shipped_strings_rig.dart';

/// The match celebration's two ring flourishes sit at the top-end and
/// bottom-start corners, so they mirror in Arabic (cleanup audit `19`,
/// run 11).
void main() {
  setUpAll(initShippedStrings);

  for (final lang in ['en', 'ar']) {
    testWidgets('$lang: the rings mirror', (tester) async {
      await pumpShippedStrings(
        tester,
        Locale(lang),
        child: const MatchSuccessScreen(),
        settle: false,
      );

      final screen = tester.getRect(find.byType(MatchSuccessScreen));
      final rings = tester.widgetList<RingMotif>(find.byType(RingMotif));
      Rect ring(double size) => tester.getRect(
        find.byWidget(rings.firstWhere((r) => r.size == size)),
      );
      final top = ring(260);
      final bottom = ring(300);

      if (lang == 'ar') {
        expect(top.left, lessThan(screen.left));
        expect(bottom.right, greaterThan(screen.right));
      } else {
        expect(top.right, greaterThan(screen.right));
        expect(bottom.left, lessThan(screen.left));
      }
    });
  }
}
