import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/match_case_stage.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'match_card_copy_harness.dart';

/// The formal-step CTA carries a helper line explaining what pressing it sets
/// in motion, and both it and the photo-exchange reject button took longer
/// wording. `QeranButton` renders its label with `maxLines: 1` and an ellipsis,
/// so a label that outgrows its slot does not wrap — it silently truncates.
///
/// The rig — real translations, shipped fonts, real theme — lives in
/// `match_card_copy_harness.dart`, which explains why each part is required.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await loadShippedFonts();
    await EasyLocalization.ensureInitialized();
  });

  group('formal-step helper', () {
    const helperKey = 'matches_formal_step_helper';

    testWidgets('reaches stage 1', (tester) async {
      await pumpMatchCard(
        tester,
        card: copyCard(MatchStage.photosExchanged),
      );

      expect(find.text(shipped(const Locale('ar'), helperKey)), findsOneWidget);
    });

    testWidgets('reaches stage 2', (tester) async {
      await pumpMatchCard(
        tester,
        card: copyCard(MatchStage.matchmakerEngaged),
      );

      expect(find.text(shipped(const Locale('ar'), helperKey)), findsOneWidget);
    });

    testWidgets('stays off stage 0, which has no formal CTA', (tester) async {
      await pumpMatchCard(
        tester,
        card: copyCard(MatchStage.waitingForPhotoExchange),
      );

      expect(find.text(shipped(const Locale('ar'), helperKey)), findsNothing);
    });
  });

  // 360dp, not 320: these read as "320dp" until the harness started
  // applying the list's own s20 inset, at which point the card they were
  // measuring turned out to be the one a 360dp screen draws. The numbers are
  // unchanged — only the label was wrong. Three of these assertions DO fail
  // at a real 320dp; that copy has never been checked there.
  group('shipped copy fits its slot at 360dp', () {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      final lang = locale.languageCode;

      testWidgets('formal-step CTA is not ellipsised [$lang]', (tester) async {
        await pumpMatchCard(
          tester,
          card: copyCard(MatchStage.matchmakerEngaged),
          locale: locale,
          size: const Size(360, 900),
        );

        final label = find.text(shipped(locale, 'matches_formal_step_cta'));
        expect(label, findsOneWidget, reason: 'CTA label not rendered');
        expect(
          isTruncated(tester, label),
          isFalse,
          reason: 'formal-step CTA truncates at 360dp in $lang',
        );
      });

      // The tightest slot in the feature: reject and accept split one card
      // width between them, so each label gets well under half of what the
      // formal CTA has to work with.
      testWidgets('photo-exchange reject is not ellipsised [$lang]', (
        tester,
      ) async {
        await pumpMatchCard(
          tester,
          card: cardAwaitingMyResponse(),
          locale: locale,
          size: const Size(360, 900),
        );

        final label = find.text(
          shipped(locale, 'matches_photo_exchange_action_reject'),
        );
        expect(label, findsOneWidget, reason: 'reject label not rendered');
        expect(
          isTruncated(tester, label),
          isFalse,
          reason: 'reject label truncates at 360dp in $lang',
        );
      });

      // The journey's collapsed summary allows two lines and then ellipsises.
      // The unified stage names made the Arabic markedly longer than what they
      // replaced — «الخطّابة تتابع» became «التواصل الرسمي مع الأهل» — and this
      // is the longest of the five, sharing its row with the glyph and the
      // disclosure chevron.
      testWidgets('the longest journey stage fits its row [$lang]', (
        tester,
      ) async {
        await pumpMatchCard(
          tester,
          card: copyCard(
            MatchStage.matchmakerEngaged,
            caseStage: MatchCaseStage.formalStepPending,
          ),
          locale: locale,
          size: const Size(360, 900),
        );

        final label = find.text(
          shipped(locale, 'matches_journey_formal_contact'),
        );
        expect(label, findsOneWidget, reason: 'journey summary not rendered');
        expect(
          isTruncated(tester, label),
          isFalse,
          reason: 'journey stage truncates at 360dp in $lang',
        );
      });
    }
  });
}
