import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_chat.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_photo_exchange_status.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_stage.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_formal_request.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_user.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/compatibility_case.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/compatibility_case_stage.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/formal_request_status.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/presentation/widgets/case_timeline.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/presentation/widgets/matchmaker_case_labels.dart';
import 'package:qeran/generated/locale_keys.g.dart';

CompatibilityCase _case({
  required CompatibilityCaseStage stage,
  FormalRequestStatus? formal,
}) {
  const user = CaseUser(
    userId: 'u',
    name: 'A',
    profileImageUrl: null,
    age: null,
    gender: null,
    isAssignedToMe: true,
  );
  return CompatibilityCase(
    caseId: 1,
    myUser: user,
    otherUser: user,
    likeAcceptedAt: null,
    stage: stage,
    photoExchange: null,
    formalRequest:
        formal == null ? null : CaseFormalRequest(id: 9, status: formal),
    chat: const CaseChat(
      myUserConversationId: null,
      otherUserConversationId: null,
      otherMatchmakerId: null,
      otherMatchmakerConversationId: null,
      otherMatchmakerName: null,
      otherMatchmakerImageUrl: null,
    ),
    canUpdateFormalRequestStatus: true,
    hasMyNote: false,
  );
}

/// Index of the single current node, or -1 if none.
int _currentIndex(List<CaseTimelineStep> steps) =>
    steps.indexWhere((s) => s.state == CaseStepState.current);

void main() {
  group('buildCaseTimeline', () {
    test('always yields the 5 canonical nodes', () {
      final steps = buildCaseTimeline(
        _case(stage: CompatibilityCaseStage.likeAccepted),
      );
      expect(steps, hasLength(5));
    });

    test('likeAccepted → current at 0, rest future', () {
      final steps = buildCaseTimeline(
        _case(stage: CompatibilityCaseStage.likeAccepted),
      );
      expect(_currentIndex(steps), 0);
      expect(steps[0].tone, CaseStepTone.normal);
      expect(steps[1].state, CaseStepState.future);
    });

    test('photoExchangePending → node 0 done, current at 1', () {
      final steps = buildCaseTimeline(
        _case(stage: CompatibilityCaseStage.photoExchangePending),
      );
      expect(steps[0].state, CaseStepState.done);
      expect(_currentIndex(steps), 1);
    });

    test('photoExchangeRejected → ended at 1 with the rejected label', () {
      final steps = buildCaseTimeline(
        _case(stage: CompatibilityCaseStage.photoExchangeRejected),
      );
      expect(_currentIndex(steps), 1);
      expect(steps[1].tone, CaseStepTone.ended);
      expect(steps[1].labelKey,
          LocaleKeys.matchmaker_cases_stage_photo_rejected);
      expect(steps[2].state, CaseStepState.future);
    });

    test('photoExchangeExpired → ended at 1 with the expired label', () {
      final steps = buildCaseTimeline(
        _case(stage: CompatibilityCaseStage.photoExchangeExpired),
      );
      expect(steps[1].tone, CaseStepTone.ended);
      expect(steps[1].labelKey,
          LocaleKeys.matchmaker_cases_stage_photo_expired);
    });

    test('formal waitingForParentAppointment → 0,1 done, current at 2', () {
      final steps = buildCaseTimeline(_case(
        stage: CompatibilityCaseStage.photoExchangeAccepted,
        formal: FormalRequestStatus.waitingForParentAppointment,
      ));
      expect(steps[0].state, CaseStepState.done);
      expect(steps[1].state, CaseStepState.done);
      expect(_currentIndex(steps), 2);
      expect(steps[2].tone, CaseStepTone.normal);
    });

    test('formal parentsVisited → current at 3', () {
      final steps = buildCaseTimeline(_case(
        stage: CompatibilityCaseStage.photoExchangeAccepted,
        formal: FormalRequestStatus.parentsVisited,
      ));
      expect(_currentIndex(steps), 3);
    });

    test('formal successfullyClosed → all done, current at 4 = success', () {
      final steps = buildCaseTimeline(_case(
        stage: CompatibilityCaseStage.photoExchangeAccepted,
        formal: FormalRequestStatus.successfullyClosed,
      ));
      expect(_currentIndex(steps), 4);
      expect(steps[4].tone, CaseStepTone.success);
      for (var i = 0; i < 4; i++) {
        expect(steps[i].state, CaseStepState.done);
      }
    });

    test('formal compatibilityClosed → ended at 2 with the closed label', () {
      final steps = buildCaseTimeline(_case(
        stage: CompatibilityCaseStage.photoExchangeAccepted,
        formal: FormalRequestStatus.compatibilityClosed,
      ));
      expect(_currentIndex(steps), 2);
      expect(steps[2].tone, CaseStepTone.ended);
      expect(steps[2].labelKey, LocaleKeys.matchmaker_cases_formal_closed);
      expect(steps[3].state, CaseStepState.future);
    });

    test('formal compatibilityCancelled → ended at 2 with cancelled label', () {
      final steps = buildCaseTimeline(_case(
        stage: CompatibilityCaseStage.photoExchangeAccepted,
        formal: FormalRequestStatus.compatibilityCancelled,
      ));
      expect(steps[2].tone, CaseStepTone.ended);
      expect(steps[2].labelKey, LocaleKeys.matchmaker_cases_formal_cancelled);
    });
  });

  // Tariq's interactive journey grew the server `stage` from five values to
  // eleven, and his migration is already applied. A stage this client does not
  // recognise parses to `unknown`, which draws no chip and drops the case back
  // onto node 0 — the production bug he fixed server-side, re-created here.
  // These guard the client half of that.
  group('every server stage places itself', () {
    // Deliberately exhaustive over the enum: a twelfth member has to be
    // answered here rather than defaulting to node 0 unnoticed.
    const expected = <CompatibilityCaseStage, (int, CaseStepTone)>{
      CompatibilityCaseStage.likeAccepted: (0, CaseStepTone.normal),
      CompatibilityCaseStage.photoExchangePending: (1, CaseStepTone.normal),
      // Photos through, formal step not yet requested — still the photo node.
      CompatibilityCaseStage.photoExchangeAccepted: (1, CaseStepTone.normal),
      CompatibilityCaseStage.photoExchangeRejected: (1, CaseStepTone.ended),
      CompatibilityCaseStage.photoExchangeExpired: (1, CaseStepTone.ended),
      // The formal step under negotiation: all three sit on the formal node.
      CompatibilityCaseStage.formalStepPending: (2, CaseStepTone.normal),
      CompatibilityCaseStage.formalStepRejected: (2, CaseStepTone.ended),
      CompatibilityCaseStage.formalStepExpired: (2, CaseStepTone.ended),
      CompatibilityCaseStage.awaitingMatchmakerCoordination:
          (2, CaseStepTone.normal),
      CompatibilityCaseStage.parentsVisited: (3, CaseStepTone.normal),
      CompatibilityCaseStage.marriageCompleted: (4, CaseStepTone.success),
      // The only member allowed to fall back to node 0.
      CompatibilityCaseStage.unknown: (0, CaseStepTone.normal),
    };

    test('the table covers every member', () {
      expect(expected.keys, containsAll(CompatibilityCaseStage.values));
      expect(expected, hasLength(CompatibilityCaseStage.values.length));
    });

    for (final entry in expected.entries) {
      final (index, tone) = entry.value;
      test('${entry.key.name} → node $index, ${tone.name}', () {
        final steps = buildCaseTimeline(_case(stage: entry.key));
        expect(_currentIndex(steps), index, reason: 'wrong node');
        expect(steps[index].tone, tone, reason: 'wrong tone');
      });
    }

    test('only unknown is allowed to land on node 0 by fallback', () {
      final onZero = CompatibilityCaseStage.values.where(
        (s) => _currentIndex(buildCaseTimeline(_case(stage: s))) == 0,
      );
      expect(
        onZero,
        [CompatibilityCaseStage.likeAccepted, CompatibilityCaseStage.unknown],
      );
    });
  });

  // The formal-step outcomes exist ONLY so these three stop borrowing the
  // photo-exchange labels. Sharing them printed "رُفض تبادل الصور" over a
  // declined formal step — the wrong event, stated with total confidence.
  group('formal-step nodes name their own event', () {
    const photoLabels = [
      LocaleKeys.matchmaker_cases_stage_photo_rejected,
      LocaleKeys.matchmaker_cases_stage_photo_expired,
    ];

    const cases = <CompatibilityCaseStage, String>{
      CompatibilityCaseStage.formalStepPending:
          LocaleKeys.matchmaker_cases_stage_formal_step_pending,
      CompatibilityCaseStage.formalStepRejected:
          LocaleKeys.matchmaker_cases_stage_formal_step_rejected,
      CompatibilityCaseStage.formalStepExpired:
          LocaleKeys.matchmaker_cases_stage_formal_step_expired,
    };

    for (final entry in cases.entries) {
      test('${entry.key.name} carries its own label, never a photo one', () {
        final steps = buildCaseTimeline(_case(stage: entry.key));
        final label = steps[_currentIndex(steps)].labelKey;
        expect(label, entry.value);
        expect(photoLabels, isNot(contains(label)));
      });
    }

    // Pending is live, not over. An ended tone would tell the matchmaker the
    // case is finished while it is simply the other member's turn.
    test('a pending formal step reads as in progress, not ended', () {
      final steps = buildCaseTimeline(
        _case(stage: CompatibilityCaseStage.formalStepPending),
      );
      expect(steps[_currentIndex(steps)].tone, CaseStepTone.normal);
    });
  });

  // Half the original breakage was the chip vanishing: stageLabelKey returned
  // null for anything unrecognised, so the card rendered no status at all.
  group('every stage can be labelled', () {
    for (final stage in CompatibilityCaseStage.values) {
      final isUnknown = stage == CompatibilityCaseStage.unknown;
      test('${stage.name} has ${isUnknown ? 'no' : 'a'} label and icon', () {
        expect(stageLabelKey(stage), isUnknown ? isNull : isNotNull);
        expect(stageIcon(stage), isUnknown ? isNull : isNotNull);
      });
    }
  });

  // The detail screen's no-actions card picks its wording from the current
  // node's tone. A case waiting for someone to request the formal step must
  // not be announced as finished.
  group('photos accepted is a waiting case, not a finished one', () {
    test('sits on the photo node, not the first formal one', () {
      final placement = caseStagePlacement(
        _case(stage: CompatibilityCaseStage.photoExchangeAccepted),
      );
      expect(placement.stage, CaseStage.photoExchange);
    });

    test('its tone drives "awaiting", never "complete"', () {
      final tone = currentCaseTone(
        _case(stage: CompatibilityCaseStage.photoExchangeAccepted),
      );
      expect(tone, CaseStepTone.normal);
      expect(
        noActionsMessageKey(tone),
        LocaleKeys.matchmaker_cases_no_actions_waiting,
      );
    });
  });

  // The five canonical node labels had NO test at all: every existing
  // labelKey assertion pinned an *override* (a rejected photo exchange, a
  // closed case), so the happy-path words the timeline actually spends most
  // of its life showing could be repointed anywhere and this file stayed
  // green. That is precisely the blast radius of a rename.
  group('canonical node labels', () {
    // Exhaustive by construction: a new CaseStage member breaks this map at
    // compile time rather than silently arriving unlabelled.
    const expected = <CaseStage, String>{
      CaseStage.likeAccepted:
          LocaleKeys.matchmaker_cases_timeline_initial_compatibility,
      CaseStage.photoExchange:
          LocaleKeys.matchmaker_cases_timeline_photo_exchange,
      CaseStage.waitingAppointment:
          LocaleKeys.matchmaker_cases_timeline_formal_contact,
      CaseStage.parentsVisited:
          LocaleKeys.matchmaker_cases_timeline_formal_meeting,
      CaseStage.completed:
          LocaleKeys.matchmaker_cases_timeline_marriage_completed,
    };

    for (final stage in CaseStage.values) {
      test('${stage.name} keeps its own label', () {
        expect(caseStageLabelKey(stage), expected[stage]);
      });
    }

    test('every node has a label the others do not share', () {
      final keys = CaseStage.values.map(caseStageLabelKey).toList();
      expect(keys.toSet(), hasLength(CaseStage.values.length));
    });

    // The reason the five were forked in the first place. Every one of them
    // was previously ALSO a status chip, a formal-status value or the status
    // card's field label, so rewording the timeline reworded a reading where
    // a stage name is the wrong part of speech. Pointing a node back at a
    // borrowed key would quietly restore that coupling; this fails instead.
    // A node's icon and its words are chosen by two switches that must agree
    // on WHICH outcomes are overridden. Nothing structural forces that: adding
    // an outcome to one and not the other produces a node whose glyph and text
    // report different events — which is the defect the stage row shipped, in
    // its other half.
    //
    // Read through the public projection: a node that is not the current one
    // always shows its own icon, so any case placed elsewhere reveals it.
    test('a node overrides its icon exactly when it overrides its words', () {
      IconData nodeIconOf(CaseStage stage) => buildCaseTimeline(
        _case(stage: CompatibilityCaseStage.likeAccepted),
      )[stage.index].icon;

      final cases = <CompatibilityCase>[
        for (final stage in CompatibilityCaseStage.values) _case(stage: stage),
        for (final formal in FormalRequestStatus.values)
          _case(
            stage: CompatibilityCaseStage.awaitingMatchmakerCoordination,
            formal: formal,
          ),
      ];

      for (final c in cases) {
        final placement = caseStagePlacement(c);
        final step = currentCaseStep(c);
        final overrodeWords =
            step.labelKey != caseStageLabelKey(placement.stage);
        final overrodeIcon = step.icon != nodeIconOf(placement.stage);
        expect(
          overrodeIcon,
          overrodeWords,
          reason: 'outcome ${placement.outcome.name}: words '
              '${overrodeWords ? "" : "not "}overridden but icon '
              '${overrodeIcon ? "" : "not "}overridden',
        );
      }
    });

    // Lockstep alone says only THAT a glyph was overridden, not which one, so
    // it stays green with a closed case wearing the photo-exchange camera —
    // found by mutation. The seven override labels are each pinned already;
    // these are their glyphs, held to the same standard.
    test('every outcome wears the glyph for its own event', () {
      const expected = <CaseStageOutcome, IconData?>{
        // null → the node keeps its own icon, the two non-override outcomes.
        CaseStageOutcome.inProgress: null,
        CaseStageOutcome.completed: null,
        CaseStageOutcome.rejected: Icons.highlight_off_rounded,
        CaseStageOutcome.expired: Icons.timer_off_outlined,
        CaseStageOutcome.closed: Icons.lock_outline_rounded,
        CaseStageOutcome.cancelled: Icons.block_rounded,
        CaseStageOutcome.formalStepPending: Icons.hourglass_top_rounded,
        CaseStageOutcome.formalStepRejected: Icons.cancel_outlined,
        CaseStageOutcome.formalStepExpired: Icons.timer_off_outlined,
      };
      // A new outcome must arrive here rather than inherit a glyph silently.
      expect(expected.keys.toSet(), CaseStageOutcome.values.toSet());

      const sources = <CaseStageOutcome, CompatibilityCaseStage>{
        CaseStageOutcome.inProgress: CompatibilityCaseStage.likeAccepted,
        CaseStageOutcome.completed: CompatibilityCaseStage.marriageCompleted,
        CaseStageOutcome.rejected: CompatibilityCaseStage.photoExchangeRejected,
        CaseStageOutcome.expired: CompatibilityCaseStage.photoExchangeExpired,
        CaseStageOutcome.formalStepPending:
            CompatibilityCaseStage.formalStepPending,
        CaseStageOutcome.formalStepRejected:
            CompatibilityCaseStage.formalStepRejected,
        CaseStageOutcome.formalStepExpired:
            CompatibilityCaseStage.formalStepExpired,
      };
      const viaFormal = <CaseStageOutcome, FormalRequestStatus>{
        CaseStageOutcome.closed: FormalRequestStatus.compatibilityClosed,
        CaseStageOutcome.cancelled: FormalRequestStatus.compatibilityCancelled,
      };

      IconData nodeIconOf(CaseStage stage) => buildCaseTimeline(
        _case(stage: CompatibilityCaseStage.likeAccepted),
      )[stage.index].icon;

      for (final outcome in CaseStageOutcome.values) {
        final c = sources.containsKey(outcome)
            ? _case(stage: sources[outcome]!)
            : _case(
                stage: CompatibilityCaseStage.awaitingMatchmakerCoordination,
                formal: viaFormal[outcome],
              );
        final placement = caseStagePlacement(c);
        expect(placement.outcome, outcome, reason: 'bad fixture for $outcome');
        expect(
          currentCaseStep(c).icon,
          expected[outcome] ?? nodeIconOf(placement.stage),
          reason: '${outcome.name} is wearing another event glyph',
        );
      }
    });

    test('every node has an icon the others do not share', () {
      final steps = buildCaseTimeline(
        _case(stage: CompatibilityCaseStage.likeAccepted),
      );
      expect(
        steps.map((s) => s.icon).toSet(),
        hasLength(CaseStage.values.length),
      );
    });

    test('no node borrows a status, formal-status or field key', () {
      final borrowed = <String>{
        ...CompatibilityCaseStage.values.map(stageLabelKey).nonNulls,
        ...FormalRequestStatus.values.map(formalStatusLabelKey).nonNulls,
        ...CasePhotoExchangeStatus.values.map(photoStatusLabelKey).nonNulls,
        // Row labels in case_status_section.dart, which has no switch to
        // sweep. cases_field_photo_exchange is here because node 1 borrowed
        // exactly it.
        LocaleKeys.matchmaker_cases_field_stage,
        LocaleKeys.matchmaker_cases_field_formal_status,
        LocaleKeys.matchmaker_cases_field_photo_exchange,
        LocaleKeys.matchmaker_cases_field_like_accepted,
      };

      for (final stage in CaseStage.values) {
        expect(
          borrowed,
          isNot(contains(caseStageLabelKey(stage))),
          reason: '${stage.name} is reading a key another screen owns',
        );
      }
    });
  });
}
