import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_stepper.dart';
import 'package:qeran/features/likes/domain/entities/formal_request.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_case_stage.dart';
import 'package:qeran/features/likes/domain/entities/match_formal_status.dart';
import 'package:qeran/features/likes/domain/entities/match_journey.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_direction.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_pending.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_status.dart';
import 'package:qeran/features/likes/presentation/widgets/match_journey_timeline.dart';

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

PhotoExchangePending get _livePending => PhotoExchangePending(
  id: 7,
  likeRequestId: 42,
  initiatorId: 'i',
  responderId: 'r',
  status: PhotoExchangeStatus.pending,
  statusCode: 0,
  remainingSeconds: 3600,
  createdAt: DateTime.now().toUtc(),
  expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
  direction: PhotoExchangeDirection.received,
  requestedByMe: false,
  canAccept: true,
  canReject: true,
);

/// Every card the projection can be handed: each server stage on its own, and
/// — because an unreadable `caseStage` falls back to the older fields — each
/// card stage on its own, with a live pending block, and against every formal
/// status.
List<MatchCard> get _everyCard => [
  for (final caseStage in MatchCaseStage.values) _card(caseStage: caseStage),
  for (final stage in MatchStage.values) ...[
    _card(stage: stage),
    _card(stage: stage, pending: _livePending),
    for (final status in MatchFormalStatus.values)
      _card(stage: stage, formalStatus: status.name),
  ],
];

int _currentIndex(List<MatchJourneyStep> steps) =>
    steps.indexWhere((s) => s.state == QeranStepState.current);

void main() {
  test('always draws all five nodes, in journey order', () {
    for (final card in _everyCard) {
      final steps = buildMatchJourney(card);
      expect(steps.length, MatchJourneyStage.values.length);
      expect(steps.map((s) => s.stage).toList(), MatchJourneyStage.values);
    }
  });

  test('exactly one node is current', () {
    for (final card in _everyCard) {
      final steps = buildMatchJourney(card);
      expect(steps.where((s) => s.state == QeranStepState.current).length, 1);
    }
  });

  // The projection this replaced opened on a node that was always already
  // behind the member. Under the unified journey the opening node is a real
  // stage a fresh match STANDS on, with nothing done behind it.
  test('a fresh match stands on the opening node with nothing done', () {
    final steps = buildMatchJourney(
      _card(caseStage: MatchCaseStage.likeAccepted),
    );

    expect(steps.first.state, QeranStepState.current);
    expect(steps.every((s) => s.state != QeranStepState.done), isTrue);
  });

  test(
    'everything before the current node is done, everything after is not',
    () {
      for (final card in _everyCard) {
        final steps = buildMatchJourney(card);
        final index = _currentIndex(steps);
        for (var i = 0; i < steps.length; i++) {
          expect(
            steps[i].state,
            i < index
                ? QeranStepState.done
                : i == index
                ? QeranStepState.current
                : QeranStepState.future,
            reason: 'node $i of ${steps.length}, current $index',
          );
        }
      }
    },
  );

  test(
    'a completed marriage lights the last node and leaves nothing pending',
    () {
      final steps = buildMatchJourney(
        _card(caseStage: MatchCaseStage.marriageCompleted),
      );

      expect(steps.last.state, QeranStepState.current);
      expect(steps.last.tone, QeranStepTone.success);
      expect(
        steps
            .take(steps.length - 1)
            .every((s) => s.state == QeranStepState.done),
        isTrue,
      );
    },
  );

  test('an in-progress journey carries no success tone', () {
    final steps = buildMatchJourney(
      _card(caseStage: MatchCaseStage.formalStepPending),
    );

    expect(steps.every((s) => s.tone == QeranStepTone.normal), isTrue);
  });

  // THE load-bearing one. A declined photo exchange, a declined formal step, a
  // closed case and a cancelled one all reach a node that carries no outcome,
  // so none of them can draw the danger cross. If someone gives _toneOf an
  // outcome to read and adds the missing `ended` branch, this is what fails.
  test('no card, in any state, ever renders an ended node', () {
    for (final card in _everyCard) {
      for (final step in buildMatchJourney(card)) {
        expect(
          step.tone,
          isNot(QeranStepTone.ended),
          reason:
              '${card.caseStage.name} / ${card.stage.name} / '
              '${card.formalRequest?.status}',
        );
      }
    }
  });
}
