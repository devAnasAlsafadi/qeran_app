import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/formal_request.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_formal_status.dart';
import 'package:qeran/features/likes/domain/entities/match_journey.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_direction.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_pending.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_status.dart';

/// Covers every backend value that can reach the journey: 4 `MatchStage`,
/// 5 `PhotoExchangeStatus`, 6 `MatchFormalStatus`.
///
/// The rule these exist to protect is the collapse. A member never sees a
/// failed journey — a rejected exchange, a closed case, a cancelled one all
/// read as "the matchmaker is following up", because that is what actually
/// happens next.
MatchCard _card({
  required MatchStage stage,
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

void main() {
  group('no formal request — the stage decides', () {
    test('an accepted like with no exchange yet sits on likeAccepted', () {
      expect(
        matchJourneyStage(_card(stage: MatchStage.waitingForPhotoExchange)),
        MatchJourneyStage.likeAccepted,
      );
    });

    // The pending block's own status is deliberately not read: accepted and
    // rejected are already expressed by the server moving `stage`, and every
    // remaining value means the same thing here.
    test('any pending block at all moves it to photoExchange', () {
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

    test('photos through, no formal request yet — the matchmaker is next', () {
      expect(
        matchJourneyStage(_card(stage: MatchStage.photosExchanged)),
        MatchJourneyStage.matchmakerFollowUp,
      );
    });

    // matchmakerEngaged means the exchange was REJECTED or they stepped in
    // directly. Both read the same to the member, which is the whole point.
    test('a rejected exchange reads as follow-up, not as a failure', () {
      expect(
        matchJourneyStage(_card(stage: MatchStage.matchmakerEngaged)),
        MatchJourneyStage.matchmakerFollowUp,
      );
    });

    test('an unrecognised stage still shows an active journey', () {
      expect(
        matchJourneyStage(_card(stage: MatchStage.unknown)),
        MatchJourneyStage.matchmakerFollowUp,
      );
    });
  });

  group('a formal request outranks the stage', () {
    test('success is the only terminal node', () {
      expect(
        matchJourneyStage(
          _card(
            stage: MatchStage.waitingForPhotoExchange,
            formalStatus: 'SuccessfullyClosed',
          ),
        ),
        MatchJourneyStage.completed,
      );
    });

    // Closed and cancelled are the business rule doing its work. The
    // matchmaker's own timeline draws a danger cross for these; the member's
    // must not.
    test('every other status — closures included — is follow-up', () {
      for (final status in MatchFormalStatus.values) {
        if (status == MatchFormalStatus.successfullyClosed) continue;
        expect(
          matchJourneyStage(
            _card(stage: MatchStage.unknown, formalStatus: status.name),
          ),
          MatchJourneyStage.matchmakerFollowUp,
          reason: status.name,
        );
      }
    });

    test('it wins even when the stage would say otherwise', () {
      expect(
        matchJourneyStage(
          _card(
            stage: MatchStage.waitingForPhotoExchange,
            pending: _pending(PhotoExchangeStatus.pending),
            formalStatus: 'ParentsVisited',
          ),
        ),
        MatchJourneyStage.matchmakerFollowUp,
      );
    });

    // The status arrives as a name or a code; the journey must not care.
    test('a numeric status reaches the same node as its name', () {
      expect(
        matchJourneyStage(_card(stage: MatchStage.unknown, formalStatus: '3')),
        MatchJourneyStage.completed,
      );
    });
  });

  // A match card exists only because a like was sent AND accepted, so the
  // first node is always already behind the member. It draws as done; it is
  // never arrived at.
  test('the journey never reports the opening node as current', () {
    for (final stage in MatchStage.values) {
      for (final formal in [
        null,
        ...MatchFormalStatus.values.map((s) => s.name),
      ]) {
        expect(
          matchJourneyStage(_card(stage: stage, formalStatus: formal)),
          isNot(MatchJourneyStage.liked),
          reason: '$stage / $formal',
        );
      }
    }
  });
}
