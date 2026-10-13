import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'match_card_copy_harness.dart';

/// The client's copy (run 7, item 8): photos are hidden until the exchange is
/// approved — never «مغبَّشة» (blurred). The stage-0 status line has two lines
/// of room; the longer sentence must fit them whole at 360.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await loadShippedFonts();
    await EasyLocalization.ensureInitialized();
  });

  const ar = Locale('ar');
  const en = Locale('en');

  test('the words', () {
    expect(
      shipped(ar, 'matches_stage_waiting_photos_title'),
      'الصور مخفية حتى الموافقة على تبادلها',
    );
    expect(
      shipped(en, 'matches_stage_waiting_photos_title'),
      'Photos stay hidden until the exchange is approved',
    );
    expect(
      shipped(ar, 'matches_action_reject_success'),
      'تم تحويل الطلب للخطّابة. تبقى الصور مخفية.',
    );
  });

  for (final locale in [ar, en]) {
    testWidgets('${locale.languageCode}: the status line fits whole at 360', (
      tester,
    ) async {
      await pumpMatchCard(
        tester,
        locale: locale,
        card: copyCard(MatchStage.waitingForPhotoExchange),
      );
      final line = find.text(
        shipped(locale, 'matches_stage_waiting_photos_title'),
      );
      expect(line, findsOneWidget);
      expect(isTruncated(tester, line), isFalse);
    });
  }
}
