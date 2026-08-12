import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_chat.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_formal_request.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_user.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/compatibility_case.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/compatibility_case_stage.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/formal_request_status.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/presentation/widgets/case_timeline.dart';
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
}
