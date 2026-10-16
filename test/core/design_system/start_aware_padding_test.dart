import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_sheet.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';
import 'package:qeran/features/matchmaker/explore/presentation/widgets/matchmaker_explore_controls.dart';

import '../shipped_strings_rig.dart';

/// Cleanup audit `19`, run 11: rows with unequal side padding keep it on the
/// right sides in Arabic too. The sheet's title row: 20 before the title, 16
/// after the close. Her Explore search row: 20 before the field, 12 after the
/// filter button.
void main() {
  setUpAll(initShippedStrings);

  /// Distances from the [outer] box's start and end edges, in reading order.
  ({double start, double end}) gaps(
    Rect outer,
    Rect first,
    Rect last, {
    required bool rtl,
  }) => rtl
      ? (start: outer.right - first.right, end: last.left - outer.left)
      : (start: first.left - outer.left, end: outer.right - last.right);

  for (final lang in ['en', 'ar']) {
    final rtl = lang == 'ar';

    testWidgets('$lang: the sheet title row', (tester) async {
      await pumpShippedStrings(
        tester,
        Locale(lang),
        child: const Align(
          alignment: Alignment.bottomCenter,
          child: QeranBottomSheetScaffold(
            title: 'T',
            body: SizedBox(height: 40),
          ),
        ),
      );

      final g = gaps(
        tester.getRect(find.byType(QeranBottomSheetScaffold)),
        tester.getRect(find.text('T')),
        tester.getRect(
          find.ancestor(
            of: find.byIcon(Icons.close_rounded),
            matching: find.byType(InkWell),
          ),
        ),
        rtl: rtl,
      );
      expect(g, (start: 20.0, end: 16.0));
    });

    testWidgets('$lang: her Explore search row', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpShippedStrings(
        tester,
        Locale(lang),
        child: MatchmakerExploreControls(
          searchController: controller,
          genderIndex: 0,
          filterActive: false,
          onSearchChanged: (_) {},
          onGenderChanged: (_) {},
          onFilterTap: () {},
        ),
      );

      final g = gaps(
        tester.getRect(find.byType(MatchmakerExploreControls)),
        tester.getRect(find.byType(QeranTextField)),
        tester.getRect(find.byType(IconButton)),
        rtl: rtl,
      );
      expect(g, (start: 20.0, end: 12.0));
    });
  }
}
