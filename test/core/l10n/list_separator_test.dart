import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_filter_searchable_facet.dart';
import 'package:qeran/core/design_system/widgets/qeran_selectable_option.dart';
import 'package:qeran/features/discovery/domain/entities/placement_item.dart';
import 'package:qeran/features/discovery/domain/entities/placement_item_type.dart';
import 'package:qeran/features/discovery/domain/entities/placement_value.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_chips_above_image.dart';

import '../shipped_strings_rig.dart';

/// A list of values reads with the language's own separator: «، » in Arabic,
/// ", " in English. The server sends the values in the app's language, so a
/// fixed Arabic comma read "Arabic، English" in English (cleanup audit `19`,
/// run 11).
void main() {
  setUpAll(initShippedStrings);

  test('lib/ joins nothing with a fixed Arabic comma', () {
    final found = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.contains('generated')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp('[\'"]، [\'"]').hasMatch(lines[i])) {
          found.add('${file.path}:${i + 1}');
        }
      }
    }
    expect(found, isEmpty);
  });

  for (final (lang, joined) in [('ar', 'A، B'), ('en', 'A, B')]) {
    testWidgets('$lang: the filter facet lists the chosen options', (
      tester,
    ) async {
      await pumpShippedStrings(
        tester,
        Locale(lang),
        child: QeranFilterSearchableFacet(
          label: 'L',
          allowsMultiple: true,
          options: const [
            QeranSelectableOption(value: 'a', display: 'A'),
            QeranSelectableOption(value: 'b', display: 'B'),
          ],
          isSelected: (_) => true,
          onTap: (_) {},
        ),
      );
      expect(find.text(joined), findsOneWidget);
    });

    testWidgets('$lang: a chip above the photo lists its values', (
      tester,
    ) async {
      await pumpShippedStrings(
        tester,
        Locale(lang),
        child: const DiscoveryChipsAboveImage(
          items: [
            PlacementItem(
              questionId: 12,
              question: 'q',
              type: PlacementItemType.checkbox,
              value: PlacementSingle('v'),
              display: PlacementMulti(['A', 'B']),
            ),
          ],
        ),
      );
      expect(find.text(joined), findsOneWidget);
    });
  }
}
