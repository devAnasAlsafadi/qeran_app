import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/match_case_stage.dart';
import 'package:qeran/features/likes/domain/entities/match_case_status.dart';
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

  // A REAL 320dp, which these did not measure until now. They were written as
  // "320dp", then found to be measuring a 360dp card once the harness started
  // applying the list's own s20 inset, and were relabelled rather than
  // retested. Dropped to the true floor here, and the copy that could not
  // survive it was shortened rather than the guard being moved back up.
  group('shipped copy fits its slot at 320dp', () {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      final lang = locale.languageCode;

      testWidgets('formal-step CTA is not ellipsised [$lang]', (tester) async {
        await pumpMatchCard(
          tester,
          card: copyCard(MatchStage.matchmakerEngaged),
          locale: locale,
          size: const Size(320, 900),
        );

        final label = find.text(shipped(locale, 'matches_formal_step_cta'));
        expect(label, findsOneWidget, reason: 'CTA label not rendered');
        expect(
          isTruncated(tester, label),
          isFalse,
          reason: 'formal-step CTA truncates at 320dp in $lang',
        );
      });

      // BOTH halves, and that is the fix as much as the copy is. Only reject
      // was ever asserted, so accept clipped in Arabic by 6.4dp for as long as
      // reject clipped by 5.5 — one guard on a symmetrical pair reports half
      // the truth, and would have let a fix ship that mismatched them.
      //
      // ⚠️ This passes for a DIFFERENT reason than when it was written. It
      // used to prove the shortened copy fitted two-across at 320dp. The
      // labels are back to their full «قبول تبادل الصور» / «رفض تبادل الصور»
      // and the pair now STACKS at this width, so what it proves today is
      // narrower: whatever layout the pair chooses at 320dp, neither label
      // ellipsises. That the choice itself is right — a row only when a row
      // fits — belongs to `match_card_photo_exchange_layout_test`.
      for (final half in const ['accept', 'reject']) {
        testWidgets('photo-exchange $half is not ellipsised [$lang]', (
          tester,
        ) async {
          await pumpMatchCard(
            tester,
            card: cardAwaitingMyResponse(),
            locale: locale,
            size: const Size(320, 900),
          );

          final label = find.text(
            shipped(locale, 'matches_photo_exchange_action_$half'),
          );
          expect(label, findsOneWidget, reason: '$half label not rendered');
          expect(
            isTruncated(tester, label),
            isFalse,
            reason: '$half label truncates at 320dp in $lang',
          );
        });
      }

      // The journey's collapsed summary allows two lines and then ellipsises.
      // The unified stage names made the Arabic markedly longer than what they
      // replaced — «الخطّابة تتابع» became «التواصل الرسمي مع الأهل» — and this
      // is the longest of the five, sharing its row with the glyph, the hint
      // and the disclosure chevron.
      //
      // English was the half that clipped, and the string was never the
      // problem: QeranStepper draws these same five labels with no maxLines at
      // all, so they wrap freely everywhere else. It clipped here alone
      // because the hint beside it is UNFLEXED, so the summary yielded until
      // it was unreadable while a fixed neighbour kept full width. Shortening
      // the hint gave the row back ~47dp; shortening the stage name would
      // have broken its pairing with the matchmaker's own five.
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
          size: const Size(320, 900),
        );

        final label = find.text(
          shipped(locale, 'matches_journey_formal_contact'),
        );
        expect(label, findsOneWidget, reason: 'journey summary not rendered');
        expect(
          isTruncated(tester, label),
          isFalse,
          reason: 'journey stage truncates at 320dp in $lang',
        );
      });

      // The ending replaces the node's name in that same slot. It is shorter
      // than the longest stage name in both languages, which is the reason it
      // cannot add a fourth clip — pinned here so a reword cannot quietly
      // make it one.
      testWidgets('the ended-journey label fits its row [$lang]', (
        tester,
      ) async {
        await pumpMatchCard(
          tester,
          card: copyCard(
            MatchStage.photosExchanged,
            caseStatus: MatchCaseStatus.cancelled,
          ),
          locale: locale,
          size: const Size(320, 900),
        );

        final label = find.text(shipped(locale, 'matches_journey_ended'));
        expect(label, findsOneWidget, reason: 'ended label not rendered');
        expect(
          isTruncated(tester, label),
          isFalse,
          reason: 'ended label truncates at 320dp in $lang',
        );
      });
    }
  });
}
