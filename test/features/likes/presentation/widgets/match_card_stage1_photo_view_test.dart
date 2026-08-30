import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'match_card_stage1_photo_harness.dart';

/// What a RUNNING case offers about photos: one reveal while the view is
/// unspent, and one muted line once it is not.
///
/// The lock half — what an ended or completed case withdraws — is
/// `match_card_stage1_photo_lock_test.dart`.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('a running case', () {
    testWidgets('offers the reveal without fetching clear bytes', (
      tester,
    ) async {
      await pumpStage1(tester, photoCard(isBlurred: false));

      expect(
        find.text(LocaleKeys.likes_matches_photo_view_show),
        findsOneWidget,
      );
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });

    // The other direction of the gate. Without this, hiding the photos
    // everywhere would pass every test below.
    testWidgets('opens the gallery from the avatar', (tester) async {
      expect(
        await opensAfterTappingAvatar(tester, photoCard(isBlurred: false)),
        1,
      );
    });

    testWidgets('the spent view is reported once, and not as a control', (
      tester,
    ) async {
      await pumpStage1(tester, photoCard(isBlurred: true));

      expect(find.text(LocaleKeys.likes_matches_photo_view_show), findsNothing);
      expect(
        find.text(LocaleKeys.likes_matches_photo_view_done),
        findsOneWidget,
      );
      // One fact, one place. The status line used to say this too, in
      // different words — the drift starts the moment either is edited.
      expect(
        find.text(LocaleKeys.likes_matches_photo_view_expired),
        findsNothing,
      );
    });

    testWidgets('a spent view closes the avatar too', (tester) async {
      expect(
        await opensAfterTappingAvatar(tester, photoCard(isBlurred: true)),
        isZero,
      );
    });
  });
}
