import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/formal_step_status.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_case_stage.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/domain/entities/pending_formal_step.dart';

/// `hasRequestedFormalStep` replaced an in-memory set that forgot the answer
/// on every restart. It decides whether the card offers to start the formal
/// step or reports that it already did, so both ways of being wrong are
/// visible: a member invited to request something they requested, or a member
/// told they are waiting on a reply that already came.
MatchCard _card({
  MatchCaseStage caseStage = MatchCaseStage.unknown,
  PendingFormalStep? pending,
}) => MatchCard(
  likeRequestId: 1,
  otherUserId: 'other',
  otherUserName: 'نور',
  images: const [],
  stage: MatchStage.photosExchanged,
  pendingPhotoExchange: null,
  formalRequest: null,
  conversationId: null,
  caseStage: caseStage,
  pendingFormalStep: pending,
);

PendingFormalStep _pending({required bool requestedByMe}) => PendingFormalStep(
  id: 5,
  likeRequestId: 1,
  status: FormalStepStatus.pending,
  remainingSeconds: 3600,
  createdAt: DateTime.now().toUtc(),
  expiresAt: DateTime.now().toUtc().add(const Duration(hours: 47)),
  direction: requestedByMe ? 'Sent' : 'Received',
  requestedByMe: requestedByMe,
  canAccept: !requestedByMe,
  canReject: !requestedByMe,
);

void main() {
  test('an open request this member sent reads as sent', () {
    expect(
      _card(
        caseStage: MatchCaseStage.formalStepPending,
        pending: _pending(requestedByMe: true),
      ).hasRequestedFormalStep,
      isTrue,
    );
  });

  // "Awaiting their approval" on a request they are waiting on ME to answer
  // names the wrong person. The receiver's own card answers this state.
  test('an open request the OTHER member sent does not', () {
    expect(
      _card(
        caseStage: MatchCaseStage.formalStepPending,
        pending: _pending(requestedByMe: false),
      ).hasRequestedFormalStep,
      isFalse,
    );
  });

  // THE one that needs the caseStage half. The block goes null the moment the
  // receiver approves; reading only the block would put the CTA back on a
  // case that has already moved past the step.
  group('the block is gone but the case moved on', () {
    for (final stage in const [
      MatchCaseStage.awaitingMatchmakerCoordination,
      MatchCaseStage.parentsVisited,
      MatchCaseStage.marriageCompleted,
    ]) {
      test('${stage.name} still reads as sent with no pending block', () {
        expect(_card(caseStage: stage).hasRequestedFormalStep, isTrue);
      });
    }
  });

  group('nothing has been asked yet', () {
    for (final stage in const [
      MatchCaseStage.likeAccepted,
      MatchCaseStage.photoExchangePending,
      MatchCaseStage.photoExchangeAccepted,
      MatchCaseStage.photoExchangeRejected,
      MatchCaseStage.photoExchangeExpired,
      MatchCaseStage.unknown,
    ]) {
      test('${stage.name} offers the CTA', () {
        expect(_card(caseStage: stage).hasRequestedFormalStep, isFalse);
      });
    }
  });

  // Declined or lapsed is OVER, not pending. Claiming "awaiting their
  // approval" there would describe a wait that ended. The ended presentation
  // is its own piece of work; until then the server refuses the retry.
  group('the step was answered and it is finished', () {
    for (final stage in const [
      MatchCaseStage.formalStepRejected,
      MatchCaseStage.formalStepExpired,
    ]) {
      test('${stage.name} does not claim a live request', () {
        expect(_card(caseStage: stage).hasRequestedFormalStep, isFalse);
      });
    }
  });

  test('every server stage is answered, none by accident', () {
    for (final stage in MatchCaseStage.values) {
      expect(_card(caseStage: stage).hasRequestedFormalStep, isA<bool>());
    }
  });

  // A synthetic card — the matchmaker's interest row, the profile seed —
  // carries no case data at all and must not claim a request was made.
  test('a card with no journey data claims nothing', () {
    const synthetic = MatchCard(
      likeRequestId: 9,
      otherUserId: 'x',
      otherUserName: 'x',
      images: [],
      stage: MatchStage.waitingForPhotoExchange,
      pendingPhotoExchange: null,
      formalRequest: null,
      conversationId: null,
    );

    expect(synthetic.hasRequestedFormalStep, isFalse);
  });
}
