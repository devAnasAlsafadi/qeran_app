import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/utils/app_assets.dart';

/// Run 8: the Suggestions tab's ring with a diamond is drawn like the Material
/// icons beside it — a 24 grid, a 2-unit stroke, round ends — so it matches
/// their weight and optical size. Selected, the gem fills; nothing else moves.
void main() {
  final outline = File(AppAssets.navRingOutline).readAsStringSync();
  final filled = File(AppAssets.navRingFilled).readAsStringSync();

  test('both states are on the icons\' grid and stroke', () {
    for (final svg in [outline, filled]) {
      expect(svg, contains('viewBox="0 0 24 24"'));
      expect(svg, contains('stroke-width="2"'));
      expect(svg, contains('stroke-linecap="round"'));
      expect(svg, contains('stroke-linejoin="round"'));
    }
  });

  test('unselected is outlined; selected only fills the gem', () {
    expect(outline, contains('fill="none"'));
    expect(outline, isNot(contains('fill="#000"')));
    expect(filled.replaceFirst(' fill="#000"', ''), outline);
  });

  testWidgets('both load as 24-unit pictures', (tester) async {
    for (final asset in [AppAssets.navRingOutline, AppAssets.navRingFilled]) {
      final info = await tester.runAsync(
        () => vg.loadPicture(SvgAssetLoader(asset), null),
      );
      expect(info!.size, const Size(24, 24));
      info.picture.dispose();
    }
  });
}
