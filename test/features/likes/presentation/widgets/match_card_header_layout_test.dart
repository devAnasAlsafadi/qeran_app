import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/presentation/widgets/match_card.dart';
import 'package:qeran/features/likes/presentation/widgets/match_pending_countdown_chip.dart';

import 'match_card_copy_harness.dart';

/// Height of a stage-0 card with no pending request, per (screen width,
/// locale), captured BEFORE the countdown moved onto its own line.
///
/// These are pinned numbers rather than a relative comparison on purpose. The
/// claim being guarded is that the chip's new line costs nothing on a card
/// that has no chip, and only a value measured on the old layout can say that
/// — a with-vs-without comparison inside one run would pass just as happily
/// if every card in the list had grown.
const Map<String, double> kChiplessCardHeight = {
  '320-ar': 292,
  '320-en': 292,
  '360-ar': 266,
  '360-en': 270,
};

/// What the match-card header can hold at the narrowest width we support,
/// measured with the SHIPPED fonts and the list's own inset.
///
/// The header row carries three things that all want the trailing edge: the
/// member's name, a live countdown chip, and (from sub-step 5d) the cancel X.
/// They do not all fit on one line. Measured at 320dp in Arabic against the
/// widest countdown the formatter can produce:
///
///   name slot beside the chip … 39.4dp   ← already ellipsised, before any X
///   the chip itself ………………… 118.6dp
///   the whole header row ………… 170.0dp
///
/// So the chip alone was taking 70% of the row and clipping real names, and
/// adding a 32dp X to the same line would have taken the name to nothing.
/// Sub-step 5d moves the chip to its own line under the name instead — the
/// element that VARIES by state is the one that moves, and the X gets a fixed
/// trailing slot.
///
/// When these were first written THREE of the four combinations below failed,
/// not just the Arabic one that prompted the work: English clips at 320dp too,
/// and Arabic clips at 360dp as well. That only shows up against
/// [kWidestCountdownSeconds] — the earlier hand probe used a days/hours
/// countdown, which is ~20dp narrower, and it read as a 320dp-Arabic-only
/// problem. The width of the worst case is doing real work here.
void main() {
  setUpAll(loadShippedFonts);

  for (final width in const [320.0, 360.0]) {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      final lang = locale.languageCode;

      testWidgets('the name survives a live countdown at ${width}dp [$lang]', (
        tester,
      ) async {
        final name = kLongNames[lang]!;
        await pumpMatchCard(
          tester,
          card: copyCard(
            MatchStage.waitingForPhotoExchange,
            name: name,
            pendingPhotoExchange: livePhotoRequestFromMe(),
          ),
          locale: locale,
          size: Size(width, 900),
        );

        expect(
          find.byType(MatchPendingCountdownChip),
          findsOneWidget,
          reason: 'the guard is worthless without the chip it guards against',
        );
        expect(
          isTruncated(tester, find.text(name)),
          isFalse,
          reason:
              'a real name is ellipsised at ${width}dp in $lang beside a live '
              'countdown. The chip and the name are competing for one row — '
              'the chip belongs on its own line beneath the name.',
        );
      });

      testWidgets(
        'the name survives a countdown AND the cancel X at ${width}dp [$lang]',
        (tester) async {
          final name = kLongNames[lang]!;
          await pumpMatchCard(
            tester,
            card: copyCard(
              MatchStage.waitingForPhotoExchange,
              name: name,
              pendingPhotoExchange: livePhotoRequestFromMe(),
            ),
            locale: locale,
            size: Size(width, 900),
            onCancelCase: () {},
          );

          expect(
            find.byIcon(Icons.close_rounded),
            findsOneWidget,
            reason: 'the X has to be on the card for this to measure anything',
          );
          expect(find.byType(MatchPendingCountdownChip), findsOneWidget);
          expect(
            isTruncated(tester, find.text(name)),
            isFalse,
            reason:
                'the name is ellipsised at ${width}dp in $lang once the X '
                'takes its share of the row. This is the case the whole '
                'layout was chosen for — if it fails, the X is back on the '
                'countdown\'s line rather than the countdown being on its own.',
          );
        },
      );

      testWidgets('a card with no countdown grows no blank row [$lang]', (
        tester,
      ) async {
        final name = kLongNames[lang]!;

        await pumpMatchCard(
          tester,
          card: copyCard(MatchStage.waitingForPhotoExchange, name: name),
          locale: locale,
          size: Size(width, 900),
        );
        final withoutChip = tester.getSize(find.byType(MatchCardWidget)).height;

        expect(
          find.byType(MatchPendingCountdownChip),
          findsNothing,
          reason: 'no pending request, so nothing to count down',
        );
        expect(
          withoutChip,
          kChiplessCardHeight['${width.toInt()}-$lang'],
          reason:
              'a chipless card changed height. Moving the countdown onto its '
              'own line must cost nothing on the cards that have no '
              'countdown — an always-present empty slot would add this row '
              'to every card in the list. Numbers pinned BEFORE the move.',
        );
      });
    }
  }
}
