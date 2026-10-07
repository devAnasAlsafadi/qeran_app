import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/community/presentation/widgets/composer/composer_copy.dart';

import '../../../../core/shipped_strings_rig.dart';

void main() {
  setUpAll(initShippedStrings);

  Future<BuildContext> inside(WidgetTester tester, String language) =>
      pumpShippedStrings(tester, Locale(language));

  testWidgets('[ar] a video limit (BA-A8, Q16): whole minutes in B1 forms, '
      'otherwise m:ss; the types; megabytes', (tester) async {
    final ar = await inside(tester, 'ar');

    expect(
      [
        for (final s in [60, 120, 180, 660, 6000, 90]) durationLimitText(ar, s),
      ],
      ['دقيقة واحدة', 'دقيقتان', '3 دقائق', '11 دقيقة', '100 دقيقة', '1:30'],
    );
    expect(imageTypesText(ar, ['jpg', 'jpeg', 'png']), 'JPG أو PNG');
    expect(videoTypesText(ar, ['mp4', 'mov']), 'MP4 أو MOV');
    expect(megabytesText(ar, 5242880), '5 ميغابايت');
  });

  testWidgets('[en] the same: minutes, m:ss, the list with "or", MB', (
    tester,
  ) async {
    final en = await inside(tester, 'en');

    expect(
      [
        for (final s in [60, 120, 90]) durationLimitText(en, s),
      ],
      ['1 minute', '2 minutes', '1:30'],
    );
    expect(imageTypesText(en, ['jpg', 'png', 'gif']), 'JPG, PNG or GIF');
    expect(imageTypesText(en, ['jpeg']), 'JPEG');
    expect(imageTypesText(en, []), 'JPG or PNG');
    expect(videoTypesText(en, []), 'MP4 or MOV');
    expect(megabytesText(en, 5452595), '5.2 MB');
    expect(megabytesText(en, 314572800), '300 MB');
  });
}
