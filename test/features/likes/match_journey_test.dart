import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/formal_request.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_case_stage.dart';
import 'package:qeran/features/likes/domain/entities/match_formal_status.dart';
import 'package:qeran/features/likes/domain/entities/match_journey.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_direction.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_pending.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_status.dart';

/// The journey now runs on `caseStage` — the server's own answer to "how far
/// did they get" — and reconstructs a position from `formalRequest` + `stage`
/// only when it cannot read that field.
///
/// Two rules these exist to protect. The five nodes are the matchmaker's five,
/// so a couple sits on the same one whoever is looking. And the fallback never
/// sends a case BACKWARDS: an unreadable stage must not park a couple whose
/// families have met back at the opening node.
MatchCard _card({
  MatchCaseStage caseStage = MatchCaseStage.unknown,
  MatchStage stage = MatchStage.unknown,
  PhotoExchangePending? pending,
  String? formalStatus,
}) => MatchCard(
  likeRequestId: 42,
  otherUserId: 'other',
  otherUserName: 'نور',
  images: const [],
  stage: stage,
  pendingPhotoExchange: pending,
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
);

PhotoExchangePending _pending(PhotoExchangeStatus status) =>
    PhotoExchangePending(
      id: 7,
      likeRequestId: 42,
      initiatorId: 'i',
      responderId: 'r',
      status: status,
      statusCode: status.index,
      remainingSeconds: 3600,
      createdAt: DateTime.now().toUtc(),
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      direction: PhotoExchangeDirection.received,
      requestedByMe: false,
      canAccept: true,
      canReject: true,
    );

/// The whole collapse, eleven server stages onto five member nodes — the same
/// collapse the matchmaker's `caseStagePlacement` performs.
const _expected = <MatchCaseStage, MatchJourneyStage>{
  MatchCaseStage.likeAccepted: MatchJourneyStage.initialCompatibility,
  MatchCaseStage.photoExchangePending: MatchJourneyStage.photoExchange,
  MatchCaseStage.photoExchangeAccepted: MatchJourneyStage.photoExchange,
  MatchCaseStage.photoExchangeRejected: MatchJourneyStage.photoExchange,
  MatchCaseStage.photoExchangeExpired: MatchJourneyStage.photoExchange,
  MatchCaseStage.formalStepPending: MatchJourneyStage.formalContact,
  MatchCaseStage.formalStepRejected: MatchJourneyStage.formalContact,
  MatchCaseStage.formalStepExpired: MatchJourneyStage.formalContact,
  MatchCaseStage.awaitingMatchmakerCoordination:
      MatchJourneyStage.formalContact,
  MatchCaseStage.parentsVisited: MatchJourneyStage.formalMeeting,
  MatchCaseStage.marriageCompleted: MatchJourneyStage.marriageCompleted,
};

void main() {
  group('caseStage places the card', () {
    test('every server stage but the fallback is accounted for', () {
      expect(
        _expected.keys.toSet(),
        MatchCaseStage.values.toSet()..remove(MatchCaseStage.unknown),
      );
    });

    for (final entry in _expected.entries) {
      test('${entry.key.name} sits on ${entry.value.name}', () {
        expect(matchJourneyStage(_card(caseStage: entry.key)), entry.value);
      });
    }

    // The formal step being ARRANGED is still the formal-contact step. Moving
    // it to the meeting node would tell the member their families are meeting
    // on the strength of the matchmaker merely picking the case up.
    test('coordination has not reached the meeting node', () {
      expect(
        matchJourneyStage(
          _card(caseStage: MatchCaseStage.awaitingMatchmakerCoordination),
        ),
        isNot(MatchJourneyStage.formalMeeting),
      );
    });
  });

  group('caseStage outranks the older fields', () {
    test('it wins over a stage that would say less', () {
      expect(
        matchJourneyStage(
          _card(
            caseStage: MatchCaseStage.parentsVisited,
            stage: MatchStage.waitingForPhotoExchange,
            pending: _pending(PhotoExchangeStatus.pending),
          ),
        ),
        MatchJourneyStage.formalMeeting,
      );
    });

    // Contradictory rows are the server's problem, not the client's: ONE field
    // decides, so the two screens cannot land on different nodes by weighing
    // the same evidence differently.
    test('it wins over a formalRequest that would say more', () {
      expect(
        matchJourneyStage(
          _card(
            caseStage: MatchCaseStage.likeAccepted,
            formalStatus: 'SuccessfullyClosed',
          ),
        ),
        MatchJourneyStage.initialCompatibility,
      );
    });
  });

  group('an unreadable caseStage rebuilds from formalRequest', () {
    test('a successful close is the only way to the last node', () {
      expect(
        matchJourneyStage(_card(formalStatus: 'SuccessfullyClosed')),
        MatchJourneyStage.marriageCompleted,
      );
    });

    test('a recorded visit reaches the meeting node', () {
      expect(
        matchJourneyStage(_card(formalStatus: 'ParentsVisited')),
        MatchJourneyStage.formalMeeting,
      );
    });

    // Closed and cancelled are the business rule doing its work. The
    // matchmaker's timeline anchors both to its first formal stage; so does
    // this, and the member is shown no dead end there.
    test('every remaining status anchors to the formal-contact node', () {
      for (final status in const [
        MatchFormalStatus.waitingForParentAppointment,
        MatchFormalStatus.compatibilityClosed,
        MatchFormalStatus.compatibilityCancelled,
        MatchFormalStatus.unknown,
      ]) {
        expect(
          matchJourneyStage(_card(formalStatus: status.name)),
          MatchJourneyStage.formalContact,
          reason: status.name,
        );
      }
    });

    test('the status arrives as a name or a code and lands the same', () {
      expect(
        matchJourneyStage(_card(formalStatus: '3')),
        matchJourneyStage(_card(formalStatus: 'SuccessfullyClosed')),
      );
    });

    // THE load-bearing one, and the reason the fallback exists at all. Sending
    // an unreadable caseStage to the first node — which is what the matchmaker
    // does with its own unknown — would visibly rewind a couple's journey
    // because one string changed spelling.
    test('a case with a formalRequest never rewinds to the opening node', () {
      for (final status in MatchFormalStatus.values) {
        final stage = matchJourneyStage(_card(formalStatus: status.name));
        expect(
          stage.index,
          greaterThanOrEqualTo(MatchJourneyStage.formalContact.index),
          reason: '${status.name} landed on ${stage.name}',
        );
      }
    });
  });

  group('an unreadable caseStage falls back to the card stage', () {
    test('an accepted like with no exchange yet opens the journey', () {
      expect(
        matchJourneyStage(_card(stage: MatchStage.waitingForPhotoExchange)),
        MatchJourneyStage.initialCompatibility,
      );
    });

    // The pending block's own status is deliberately not read: accepted and
    // rejected are already expressed by the server moving `stage`.
    test('any pending block at all moves it to the photo node', () {
      for (final status in PhotoExchangeStatus.values) {
        expect(
          matchJourneyStage(
            _card(
              stage: MatchStage.waitingForPhotoExchange,
              pending: _pending(status),
            ),
          ),
          MatchJourneyStage.photoExchange,
          reason: status.name,
        );
      }
    });

    // Both of these used to reach the merged follow-up node. Under the
    // interactive journey nobody has requested the formal step yet, so
    // claiming the formal node would announce a step neither member took.
    test('photos through, or declined, stays on the photo node', () {
      for (final stage in const [
        MatchStage.photosExchanged,
        MatchStage.matchmakerEngaged,
      ]) {
        expect(
          matchJourneyStage(_card(stage: stage)),
          MatchJourneyStage.photoExchange,
          reason: stage.name,
        );
      }
    });

    // Nothing on the row is readable. A match card existing is still proof a
    // like was accepted, and that is the only claim left to make.
    test('a row with nothing readable claims only the opening node', () {
      expect(
        matchJourneyStage(_card()),
        MatchJourneyStage.initialCompatibility,
      );
    });

    test('a formalRequest outranks the card stage inside the fallback', () {
      expect(
        matchJourneyStage(
          _card(
            stage: MatchStage.waitingForPhotoExchange,
            pending: _pending(PhotoExchangeStatus.pending),
            formalStatus: 'ParentsVisited',
          ),
        ),
        MatchJourneyStage.formalMeeting,
      );
    });
  });
}
