import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_premium_banner.dart';

import '../shipped_strings_rig.dart';

/// The wine gradients light the reading start (top-left in English,
/// top-right in Arabic), never a fixed physical corner (cleanup audit `19`,
/// run 11).
void main() {
  setUpAll(initShippedStrings);

  final physical = RegExp(r'Alignment\.(top|center|bottom)(Left|Right)');

  // A symmetric shimmer (clear, gold, clear) painted by a CustomPainter, which
  // has no text direction to resolve a directional alignment with.
  const symmetric = {'qeran_skeleton.dart'};

  test('gradients in lib/ use directional alignments', () {
    final found = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (symmetric.contains(file.uri.pathSegments.last)) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (physical.hasMatch(lines[i])) found.add('${file.path}:${i + 1}');
      }
    }
    expect(found, isEmpty);
  });

  for (final lang in ['ar', 'en']) {
    testWidgets('$lang: the premium banner paints its gradient', (
      tester,
    ) async {
      await pumpShippedStrings(
        tester,
        Locale(lang),
        child: const QeranPremiumBanner(title: 'T', subtitle: 'S'),
      );

      final box = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(QeranPremiumBanner),
              matching: find.byType(Container),
            )
            .first,
      );
      final gradient =
          (box.decoration! as BoxDecoration).gradient! as LinearGradient;
      expect(gradient.begin, AlignmentDirectional.topStart);
      expect(gradient.end, AlignmentDirectional.bottomEnd);
      expect(tester.takeException(), isNull);
    });
  }
}
