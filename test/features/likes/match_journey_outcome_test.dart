import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/formal_request.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_case_stage.dart';
import 'package:qeran/features/likes/domain/entities/match_case_status.dart';
import 'package:qeran/features/likes/domain/entities/match_formal_status.dart';
import 'package:qeran/features/likes/domain/entities/match_journey_outcome.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';

/// The reversal of the old blanket rule, which said no member card could ever
/// read as ended. Three endings now do, and the value of these tests is
/// entirely in what they REFUSE: a rule this narrow is only narrow while
/// something fails when it widens.
MatchCard _card({
  MatchCaseStage caseStage = MatchCaseStage.unknown,
  MatchCaseStatus caseStatus = MatchCaseStatus.active,
  MatchStage stage = MatchStage.unknown,
  String? formalStatus,
}) => MatchCard(
  likeRequestId: 42,
  otherUserId: 'other',
  otherUserName: 'نور',
  images: const [],
  stage: stage,
  pendingPhotoExchange: null,
  formalRequest: formalStatus == null
      ? null
      : FormalRequest(
          id: 1,
          maleUserId: 'm',
          maleUserName: 'm',
          femaleUserId: 'f',
          femaleUserName: 'f',
          status: formalStatus,
          statusNameAr: '',
          statusNameEn: '',
          updatedByMatchmakerAt: null,
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
  conversationId: null,
  caseStage: caseStage,
  caseStatus: caseStatus,
);

void main() {
  group('the three endings, and only the three', () {
    test('the member cancelled it — Cancelled', () {
      expect(
        matchJourneyHasEnded(_card(caseStatus: MatchCaseStatus.cancelled)),
        isTrue,
      );
    });

    test('the matchmaker recorded «لم ينجح» — Failed', () {
      expect(
        matchJourneyHasEnded(_card(caseStatus: MatchCaseStatus.failed)),
        isTrue,
      );
    });

    // The odd one out, and deliberately so: cancelling leaves the stage where
    // it stood and writes the ending on `caseStatus`, while declining a formal
    // step moves the STAGE. Reading one field would miss one ending.
    test('the receiver declined the formal step — a stage, not a status', () {
      expect(
        matchJourneyHasEnded(
          _card(caseStage: MatchCaseStage.formalStepRejected),
        ),
        isTrue,
      );
    });

    // THE one that catches `caseStatus.isEnded` being substituted for the
    // spelled-out pair. That getter covers `completed` as well, and a wedding
    // drawn with a danger cross is the worst thing this file can let through.
    test('a completed marriage has NOT ended — that is the success outcome', () {
      expect(
        matchJourneyHasEnded(
          _card(
            caseStatus: MatchCaseStatus.completed,
            caseStage: MatchCaseStage.marriageCompleted,
          ),
        ),
        isFalse,
      );
    });

    test('every status is accounted for, so a new one cannot default in', () {
      const ending = {MatchCaseStatus.cancelled, MatchCaseStatus.failed};
      for (final status in MatchCaseStatus.values) {
        expect(
          matchJourneyHasEnded(_card(caseStatus: status)),
          ending.contains(status),
          reason: status.name,
        );
      }
    });

    // Agrees with `MatchCardCancelAction.isAvailable`, the only other
    // member-side reader of this field: an unrecognised status is not a fact,
    // so one omits the X and the other omits the ending.
    test('an unrecognised status omits rather than guesses', () {
      expect(
        matchJourneyHasEnded(_card(caseStatus: MatchCaseStatus.unknown)),
        isFalse,
      );
    });
  });

  group('a running case keeps running', () {
    // The case the whole rule was written to protect, and the reason this
    // revision had to be narrow: the matchmaker takes a declined exchange over
    // and carries on, so the member is shown no dead end.
    test('only formalStepRejected ends it — every other stage runs on', () {
      for (final stage in MatchCaseStage.values) {
        expect(
          matchJourneyHasEnded(_card(caseStage: stage)),
          stage == MatchCaseStage.formalStepRejected,
          reason: stage.name,
        );
      }
    });

    test('a lapsed formal step is not a refusal', () {
      expect(
        matchJourneyHasEnded(_card(caseStage: MatchCaseStage.formalStepExpired)),
        isFalse,
      );
    });

    test('an empty row claims nothing', () {
      expect(matchJourneyHasEnded(_card()), isFalse);
      for (final stage in MatchStage.values) {
        expect(matchJourneyHasEnded(_card(stage: stage)), isFalse,
            reason: stage.name);
      }
    });
  });

  group('the older fields spell the same endings', () {
    // A row old enough to carry no readable `caseStage` may predate
    // `caseStatus` entirely, which `fromWire` reads as active. Without this
    // branch those two closures are the one place a genuinely ended case still
    // draws as live.
    test('CompatibilityClosed and CompatibilityCancelled end it', () {
      for (final status in const ['CompatibilityClosed', 'CompatibilityCancelled']) {
        expect(matchJourneyHasEnded(_card(formalStatus: status)), isTrue,
            reason: status);
      }
    });

    test('SuccessfullyClosed does not — that is the marriage', () {
      expect(
        matchJourneyHasEnded(_card(formalStatus: 'SuccessfullyClosed')),
        isFalse,
      );
    });

    test('every formal status is accounted for', () {
      const ending = {
        MatchFormalStatus.compatibilityClosed,
        MatchFormalStatus.compatibilityCancelled,
      };
      for (final status in MatchFormalStatus.values) {
        expect(
          matchJourneyHasEnded(_card(formalStatus: status.name)),
          ending.contains(status),
          reason: status.name,
        );
      }
    });

    // The status arrives as a name or as a numeric code; `fromWire` maps both,
    // and this branch has to read it through that rather than by string match.
    test('a numeric code lands the same as its name', () {
      expect(
        matchJourneyHasEnded(_card(formalStatus: '4')),
        matchJourneyHasEnded(_card(formalStatus: 'CompatibilityClosed')),
      );
    });

    // The guard that keeps this a FALLBACK. A live case whose stage the server
    // reports perfectly well must never have its ending re-litigated from a
    // frozen legacy field — the backend stops updating `formalRequest` once
    // `caseStage` is authoritative.
    test('they are read only when caseStage is unreadable', () {
      for (final stage in MatchCaseStage.values) {
        if (stage == MatchCaseStage.unknown) continue;
        expect(
          matchJourneyHasEnded(
            _card(caseStage: stage, formalStatus: 'CompatibilityCancelled'),
          ),
          stage == MatchCaseStage.formalStepRejected,
          reason: stage.name,
        );
      }
    });
  });
}
