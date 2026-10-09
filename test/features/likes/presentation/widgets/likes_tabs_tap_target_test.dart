import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/likes_tab.dart';
import 'package:qeran/features/likes/presentation/widgets/likes_segmented_tabs.dart';

import '../../../../core/shipped_strings_rig.dart';

/// R5: the member's Likes tabs are a real 48 pt target, like hers (D2) — the
/// track's inner padding no longer eats two points from each segment.
void main() {
  setUpAll(initShippedStrings);

  for (final locale in const [Locale('ar'), Locale('en')]) {
    testWidgets(
      'every segment is 48 pt, at 360 wide [${locale.languageCode}]',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpShippedStrings(
          tester,
          locale,
          child: LikesSegmentedTabs(active: LikesTab.sent, onChanged: (_) {}),
        );
        expect(tester.takeException(), isNull);

        final cells = tester.widgetList(
          find.descendant(
            of: find.byType(LikesSegmentedTabs),
            matching: find.byType(InkWell),
          ),
        );
        expect(cells, hasLength(3));
        for (final cell in cells) {
          expect(tester.getSize(find.byWidget(cell)).height, 48);
        }
      },
    );
  }
}
