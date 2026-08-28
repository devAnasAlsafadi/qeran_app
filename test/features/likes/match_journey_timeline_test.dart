import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_stepper.dart';
import 'package:qeran/features/likes/domain/entities/formal_request.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_case_stage.dart';
import 'package:qeran/features/likes/domain/entities/match_case_status.dart';
import 'package:qeran/features/likes/domain/entities/match_formal_status.dart';
import 'package:qeran/features/likes/domain/entities/match_journey.dart';
import 'package:qeran/features/likes/domain/entities/match_journey_outcome.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_direction.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_pending.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_status.dart';
import 'package:qeran/features/likes/presentation/widgets/match_journey_timeline.dart';
import 'package:qeran/generated/locale_keys.g.dart';

MatchCard _card({
  MatchCaseStage caseStage = MatchCaseStage.unknown,
  MatchCaseStatus caseStatus = MatchCaseStatus.active,
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
  caseStatus: caseStatus,
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
/// status. Every one of them carries a RUNNING status; the endings have their
/// own fixtures below.
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

  // THE load-bearing pair, and it has to fail BOTH ways. The rule used to be
  // "no card ever ends"; it is now "these three end and nothing else does",
  // which is only a narrow rule while something breaks when it widens.
  group('the ending is narrow', () {
    // ONE direction, and deliberately only one: across every stage, every card
    // stage and every formal status, the timeline may not invent an ending the
    // outcome does not claim. This is what catches `_toneOf` growing a branch
    // of its own — the way the whole projection went wrong before.
    //
    // The other direction is pinned by the named fixtures below, spelled as
    // literal states. Asserting both here would mean asking the same function
    // twice and calling the agreement a test.
    test('no node ends unless the outcome says the journey has', () {
      for (final card in _everyCard) {
        for (final step in buildMatchJourney(card)) {
          if (step.tone != QeranStepTone.ended) continue;
          expect(
            matchJourneyHasEnded(card),
            isTrue,
            reason:
                '${card.caseStage.name} / ${card.stage.name} / '
                '${card.formalRequest?.status}',
          );
        }
      }
    });

    // The photo exchange is the case the whole rule exists for: the matchmaker
    // takes a declined or lapsed one over and keeps working, so the member is
    // shown no dead end. This is what fails if the reversal is ever widened to
    // the matchmaker's rule.
    test('a declined or lapsed photo exchange keeps the journey moving', () {
      for (final stage in const [
        MatchCaseStage.photoExchangeRejected,
        MatchCaseStage.photoExchangeExpired,
      ]) {
        final steps = buildMatchJourney(_card(caseStage: stage));
        expect(
          steps.every((s) => s.tone == QeranStepTone.normal),
          isTrue,
          reason: stage.name,
        );
      }
    });

    for (final entry in _endings.entries) {
      test('${entry.key} ends the journey', () {
        final steps = buildMatchJourney(entry.value);
        final current = steps.firstWhere(
          (s) => s.state == QeranStepState.current,
        );

        expect(current.tone, QeranStepTone.ended);
        expect(current.labelKey, LocaleKeys.likes_matches_journey_ended);
      });
    }

    // The ending is an OUTCOME, and only the node the member is standing on
    // has one. Carrying the tone or the label down the column would announce
    // the same ending five times.
    test('only the current node carries the ending', () {
      for (final card in _endings.values) {
        for (final step in buildMatchJourney(card)) {
          if (step.state == QeranStepState.current) continue;
          expect(step.tone, QeranStepTone.normal, reason: step.stage.name);
          expect(
            step.labelKey,
            isNot(LocaleKeys.likes_matches_journey_ended),
            reason: step.stage.name,
          );
        }
      }
    });

    // `caseStatus.isEnded` also covers `completed`. Swapping it in for the
    // spelled-out pair compiles, reads better, and puts a danger cross on a
    // wedding — this is what refuses it.
    test('a completed marriage stays a success, never an ending', () {
      final steps = buildMatchJourney(
        _card(
          caseStage: MatchCaseStage.marriageCompleted,
          caseStatus: MatchCaseStatus.completed,
        ),
      );

      expect(steps.last.tone, QeranStepTone.success);
      expect(
        steps.last.labelKey,
        LocaleKeys.likes_matches_journey_marriage_completed,
      );
    });

    // Contradictory server state: a case standing on the marriage node with a
    // Cancelled status beside it. The node wins. Of the two wrong answers
    // available for input that cannot be true, a danger cross on a wedding is
    // much the worse.
    test('the marriage node outranks an ending beside it', () {
      final steps = buildMatchJourney(
        _card(
          caseStage: MatchCaseStage.marriageCompleted,
          caseStatus: MatchCaseStatus.cancelled,
        ),
      );

      expect(steps.last.tone, QeranStepTone.success);
    });

    // Agrees with `MatchCardCancelAction.isAvailable`, the only other
    // member-side reader of this field: an unrecognised status is not a fact,
    // so one omits the X and the other omits the ending.
    test('an unrecognised status is not an ending', () {
      final steps = buildMatchJourney(
        _card(caseStatus: MatchCaseStatus.unknown),
      );

      expect(steps.every((s) => s.tone == QeranStepTone.normal), isTrue);
    });
  });

  // Where an ending PARKS the member is still the placement's answer, not the
  // outcome's — cancelling does not move the stage, so a case cancelled at the
  // photo step ends on the photo node. The neutral label is what stops that
  // reading as "the photo exchange failed".
  test('an ending does not move the node the member stands on', () {
    final cancelledAtPhotos = buildMatchJourney(
      _card(
        caseStage: MatchCaseStage.photoExchangePending,
        caseStatus: MatchCaseStatus.cancelled,
      ),
    );

    expect(
      _currentIndex(cancelledAtPhotos),
      MatchJourneyStage.photoExchange.index,
    );
  });

  // Every node that is not reporting an ending keeps its own canonical name,
  // in journey order. The five-key map went private once the step started
  // carrying its own key, so this is what pins it — through the shipped path.
  test('a running journey names all five nodes canonically', () {
    final steps = buildMatchJourney(
      _card(caseStage: MatchCaseStage.formalStepPending),
    );

    expect(steps.map((s) => s.labelKey).toList(), const [
      LocaleKeys.likes_matches_journey_initial_compatibility,
      LocaleKeys.likes_matches_journey_photo_exchange,
      LocaleKeys.likes_matches_journey_formal_contact,
      LocaleKeys.likes_matches_journey_formal_meeting,
      LocaleKeys.likes_matches_journey_marriage_completed,
    ]);
  });
}

/// One card per ending, each arriving by the route the backend actually uses:
/// cancel writes `caseStatus` and leaves the stage alone, the matchmaker's
/// «لم ينجح» writes it too, and a declined formal step writes the STAGE and
/// leaves the status running. The fourth is the legacy spelling, for a row too
/// old to carry a readable stage.
Map<String, MatchCard> get _endings => {
  'the member cancelled': _card(caseStatus: MatchCaseStatus.cancelled),
  'the matchmaker recorded it did not work': _card(
    caseStage: MatchCaseStage.parentsVisited,
    caseStatus: MatchCaseStatus.failed,
  ),
  'the receiver declined the formal step': _card(
    caseStage: MatchCaseStage.formalStepRejected,
  ),
  'a legacy row closed in formalRequest': _card(
    formalStatus: 'CompatibilityClosed',
  ),
};
