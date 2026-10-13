import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/utils/app_assets.dart';

/// Run 8: the Suggestions tab's ring with a diamond is drawn like the Material
/// icons beside it — a 24 grid, a 2-unit stroke, round ends — so it matches
/// their weight and optical size. The gem carries facets, as the old diamond
/// did: a girdle across it and a V to its point. Unselected they are stroked;
/// selected the gem fills and the facets are cut out of it, so the gold disc
/// shows through them as light lines.

final _outline = File(AppAssets.navRingOutline).readAsStringSync();
final _filled = File(AppAssets.navRingFilled).readAsStringSync();

/// Each `<path>`'s attributes, in order.
List<Map<String, String>> _paths(String svg) => [
  for (final path in RegExp(r'<path ([^>]*)/>').allMatches(svg))
    {
      for (final a in RegExp(r'([\w-]+)="([^"]*)"').allMatches(path[1]!))
        a[1]!: a[2]!,
    },
];

/// [asset] drawn 4× (96 px), and the alpha at grid point ([x], [y]).
Future<int Function(double x, double y)> _alpha(
  WidgetTester tester,
  String asset,
) async {
  final bytes = await tester.runAsync(() async {
    final info = await vg.loadPicture(SvgAssetLoader(asset), null);
    final recorder = ui.PictureRecorder();
    Canvas(recorder)
      ..scale(4)
      ..drawPicture(info.picture);
    final image = await recorder.endRecording().toImage(96, 96);
    info.picture.dispose();
    return image.toByteData();
  });
  return (x, y) =>
      bytes!.getUint8(((y * 4).round() * 96 + (x * 4).round()) * 4 + 3);
}

void main() {
  test('both states are on the icons\' grid and stroke', () {
    for (final svg in [_outline, _filled]) {
      expect(svg, contains('viewBox="0 0 24 24"'));
      expect(svg, contains('stroke-width="2"'));
      expect(svg, contains('stroke-linecap="round"'));
      expect(svg, contains('stroke-linejoin="round"'));
    }
  });

  test('unselected: the gem, its three facet lines and the ring, stroked', () {
    final paths = _paths(_outline);
    expect(paths, hasLength(3));
    expect(paths.where((p) => p.containsKey('fill')), isEmpty);
    expect('M'.allMatches(paths[1]['d']!), hasLength(3));
  });

  test('selected: the same gem and ring; the gem filled, its three facets cut '
      'out of it', () {
    final outline = _paths(_outline);
    final filled = _paths(_filled);
    expect(filled.first['d'], outline.first['d']);
    expect(filled.last['d'], outline.last['d']);
    final gem = filled[1];
    expect(gem['fill'], '#000');
    expect(gem['fill-rule'], 'evenodd');
    expect(gem['stroke'], 'none');
    expect(gem['d']!.startsWith(outline.first['d']!), isTrue);
    expect('Z'.allMatches(gem['d']!), hasLength(1 + 3));
  });

  testWidgets('drawn: stroked facets unselected, light facets selected', (
    tester,
  ) async {
    final outline = await _alpha(tester, AppAssets.navRingOutline);
    final filled = await _alpha(tester, AppAssets.navRingFilled);

    // The girdle, mid-gem; a V facet line; the pavilion between the V.
    expect(outline(12, 5.5), greaterThan(200));
    expect(filled(12, 5.5), lessThan(60));
    expect(outline(10.5, 8), greaterThan(200));
    expect(filled(10.5, 8), lessThan(60));
    expect(filled(12, 8), greaterThan(200));
    // Between the gem's top and its girdle: open unselected, filled selected.
    expect(outline(12, 3.8), lessThan(60));
    expect(filled(12, 3.8), greaterThan(200));
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
