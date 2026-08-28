import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/formal_step_status.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_case_stage.dart';
import 'package:qeran/features/likes/domain/entities/match_case_status.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/domain/entities/pending_formal_step.dart';
import 'package:qeran/features/likes/presentation/widgets/match_card_cancel_action.dart';

import 'match_card_copy_harness.dart';

/// Who gets a way out of a compatibility case, and who does not.
///
/// The rule has three clauses and each one is here on its own, because each
/// one fails differently: clause 1 wrong shows an X on a case that has already
/// ended, clause 2 wrong offers to end a completed marriage, and clause 3
/// wrong puts two irreversible controls on one card.

PendingFormalStep _formalStep({
  required bool canAccept,
  required bool canReject,
  FormalStepStatus status = FormalStepStatus.pending,
}) => PendingFormalStep(
  id: 77,
  likeRequestId: 1,
  status: status,
  remainingSeconds: 3600,
  createdAt: DateTime.utc(2026),
  expiresAt: DateTime.utc(2099),
  direction: 'Received',
  requestedByMe: false,
  canAccept: canAccept,
  canReject: canReject,
);

void main() {
  group('clause 1 — only a case that is still running', () {
    // Exhaustive over MatchCaseStatus so a new member cannot default to
    // showing the X. `active` is the only one that may.
    for (final status in MatchCaseStatus.values) {
      final expected = status == MatchCaseStatus.active;
      test('$status ${expected ? 'offers' : 'refuses'} a way out', () {
        final card = copyCard(MatchStage.photosExchanged, caseStatus: status);

        expect(MatchCardCancelAction.isAvailable(card), expected);
      });
    }

    test('an unrecognised status is NOT treated as cancellable', () {
      final card = copyCard(
        MatchStage.photosExchanged,
        caseStatus: MatchCaseStatus.unknown,
      );

      expect(
        MatchCardCancelAction.isAvailable(card),
        isFalse,
        reason:
            'MatchCaseStatus.unknown means the server sent a status this '
            'build has never heard of. Writing the clause as '
            '`!caseStatus.isEnded` passes every other row in this group and '
            'fails only this one — it would offer to end a case whose state '
            'we cannot describe. `== active` omits rather than guesses.',
      );
    });
  });

  group('clause 2 — never a completed marriage', () {
    // Exhaustive over MatchCaseStage, holding the status at `active`. That
    // combination is the whole reason this clause exists: caseStatus says how
    // a case ENDED and caseStage says how far it GOT, so a case can stand on
    // the marriage stage while its status is still active. Clause 1 does not
    // catch it.
    for (final stage in MatchCaseStage.values) {
      final expected = stage != MatchCaseStage.marriageCompleted;
      test('$stage ${expected ? 'offers' : 'refuses'} a way out', () {
        final card = copyCard(
          MatchStage.matchmakerEngaged,
          caseStage: stage,
          caseStatus: MatchCaseStatus.active,
        );

        expect(
          MatchCardCancelAction.isAvailable(card),
          expected,
          reason: stage == MatchCaseStage.marriageCompleted
              ? 'the marriage went ahead; there is nothing left to end, and '
                    'an X here is worse than no X at all'
              : 'a live case at $stage can still be called off',
        );
      });
    }
  });

  group('clause 3 — not while a formal step waits on me', () {
    test('a step awaiting MY answer hides the X', () {
      final card = copyCard(
        MatchStage.photosExchanged,
        pendingFormalStep: _formalStep(canAccept: true, canReject: true),
      );

      expect(
        card.pendingFormalStep!.isAwaitingMyResponse,
        isTrue,
        reason: 'the fixture has to actually be in the state under test',
      );
      expect(
        MatchCardCancelAction.isAvailable(card),
        isFalse,
        reason:
            'that card already carries «عدم الموافقة وإنهاء التوافق», which '
            'ends the case by itself. Two controls for one irreversible '
            'outcome — one of them a bare glyph — is a mis-tap waiting to '
            'happen.',
      );
    });

    test('a step waiting on THEM leaves the X alone', () {
      final card = copyCard(
        MatchStage.photosExchanged,
        pendingFormalStep: _formalStep(canAccept: false, canReject: false),
      );

      expect(
        MatchCardCancelAction.isAvailable(card),
        isTrue,
        reason:
            'I asked and they have not answered. Nothing on this card ends '
            'the case, so the X is the only way out and must stay.',
      );
    });

    test('a lapsed step leaves the X alone', () {
      final card = copyCard(
        MatchStage.photosExchanged,
        pendingFormalStep: _formalStep(
          canAccept: true,
          canReject: true,
          status: FormalStepStatus.rejected,
        ),
      );

      expect(
        MatchCardCancelAction.isAvailable(card),
        isTrue,
        reason:
            'the block is still attached but the request is over, so the '
            'decline button it would have carried is gone too. Reading the '
            'BLOCK rather than isAwaitingMyResponse would hide the X on a '
            'card with no other exit.',
      );
    });
  });

  group('the rendered control', () {
    setUpAll(loadShippedFonts);

    testWidgets('a card with no cancel callback shows no X', (tester) async {
      await pumpMatchCard(tester, card: copyCard(MatchStage.photosExchanged));

      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    // Each clause again, but through the RENDERED card with a callback in
    // hand. The group above proves `isAvailable` answers correctly; these
    // prove `resolve` actually asks it. Dropping the `!isAvailable(card)`
    // check from `resolve` passes every test above and fails all three here —
    // a rule nothing consults is decoration.
    final refused = <String, MatchCard>{
      'an ended case': copyCard(
        MatchStage.photosExchanged,
        caseStatus: MatchCaseStatus.cancelled,
      ),
      'a completed marriage': copyCard(
        MatchStage.matchmakerEngaged,
        caseStage: MatchCaseStage.marriageCompleted,
      ),
      'a formal step awaiting me': copyCard(
        MatchStage.photosExchanged,
        pendingFormalStep: _formalStep(canAccept: true, canReject: true),
      ),
    };

    for (final entry in refused.entries) {
      testWidgets('${entry.key} renders no X even with a callback', (
        tester,
      ) async {
        await pumpMatchCard(tester, card: entry.value, onCancelCase: () {});

        expect(find.byIcon(Icons.close_rounded), findsNothing);
      });
    }

    testWidgets('confirming ends the case', (tester) async {
      var cancelled = 0;
      await pumpMatchCard(
        tester,
        card: copyCard(MatchStage.photosExchanged),
        onCancelCase: () => cancelled++,
      );

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(
        cancelled,
        isZero,
        reason: 'the tap opens the dialog; it does not end anything yet',
      );

      await tester.tap(
        find.text(
          shipped(const Locale('ar'), 'matches_case_end_confirm_action'),
        ),
      );
      await tester.pumpAndSettle();

      expect(cancelled, 1);
    });

    testWidgets('dismissing the dialog ends nothing', (tester) async {
      var cancelled = 0;
      await pumpMatchCard(
        tester,
        card: copyCard(MatchStage.photosExchanged),
        onCancelCase: () => cancelled++,
      );

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(shippedSection(const Locale('ar'), 'common', 'cancel')),
      );
      await tester.pumpAndSettle();

      expect(
        cancelled,
        isZero,
        reason: 'backing out of an irreversible dialog must be free',
      );
    });

    // The whole card is an InkWell opening the profile. Tapping the X must
    // not also open the profile of the person the member is trying to leave.
    testWidgets('the X absorbs its own tap', (tester) async {
      var cancelled = 0;
      var profileOpened = 0;
      await pumpMatchCard(
        tester,
        card: copyCard(MatchStage.photosExchanged),
        onCancelCase: () => cancelled++,
        onOpenProfile: () => profileOpened++,
      );

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(
        profileOpened,
        isZero,
        reason:
            'the tap reached the card behind the X. A dialog over a profile '
            'screen that just pushed itself is not the flow.',
      );
      await tester.tap(
        find.text(
          shipped(const Locale('ar'), 'matches_case_end_confirm_action'),
        ),
      );
      await tester.pumpAndSettle();
      expect(cancelled, 1);
      expect(profileOpened, isZero);
    });

    testWidgets('an in-flight cancel shows a spinner, not a tappable X', (
      tester,
    ) async {
      var cancelled = 0;
      await pumpMatchCard(
        tester,
        card: copyCard(MatchStage.photosExchanged),
        onCancelCase: () => cancelled++,
        isCancelling: true,
        settle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.byIcon(Icons.close_rounded),
        findsNothing,
        reason: 'a second cancel while the first is in flight is not offered',
      );
      expect(cancelled, isZero);
    });
  });
}
