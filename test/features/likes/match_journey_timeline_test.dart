import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_stepper.dart';
import 'package:qeran/features/likes/domain/entities/formal_request.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_formal_status.dart';
import 'package:qeran/features/likes/domain/entities/match_journey.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_direction.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_pending.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_status.dart';
import 'package:qeran/features/likes/presentation/widgets/match_journey_timeline.dart';

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

/// Every card the projection can be handed: each stage on its own, each with a
/// live pending block, and each against every formal status.
List<MatchCard> get _everyCard => [
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

  // A match card exists only because a like was sent AND accepted, so the
  // opening node is behind the member before they ever see the card.
  test('the opening node is always already done', () {
    for (final card in _everyCard) {
      expect(buildMatchJourney(card).first.state, QeranStepState.done);
    }
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
    'a successful close lights the last node and leaves nothing pending',
    () {
      final steps = buildMatchJourney(
        _card(stage: MatchStage.unknown, formalStatus: 'SuccessfullyClosed'),
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
      _card(stage: MatchStage.waitingForPhotoExchange),
    );

    expect(steps.every((s) => s.tone == QeranStepTone.normal), isTrue);
  });

  // THE load-bearing one. A rejected exchange, a closed case and a cancelled
  // case are all folded into "the matchmaker is following up" upstream, so no
  // node may ever draw the danger cross. If someone adds the missing `ended`
  // branch to _toneOf, this is what fails.
  test('no card, in any state, ever renders an ended node', () {
    for (final card in _everyCard) {
      for (final step in buildMatchJourney(card)) {
        expect(
          step.tone,
          isNot(QeranStepTone.ended),
          reason: '${card.stage} / ${card.formalRequest?.status}',
        );
      }
    }
  });
}
