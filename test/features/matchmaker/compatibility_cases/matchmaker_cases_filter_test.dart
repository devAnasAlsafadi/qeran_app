import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_chat.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_formal_request.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_stage.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_user.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/compatibility_case.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/compatibility_case_stage.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/formal_request_status.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/matchmaker_cases_filter.dart';

const _chat = CaseChat(
  myUserConversationId: null,
  otherUserConversationId: null,
  otherMatchmakerId: null,
  otherMatchmakerConversationId: null,
  otherMatchmakerName: null,
  otherMatchmakerImageUrl: null,
);

CaseUser _user(String name) => CaseUser(
  userId: name,
  firstName: name,
  profileImageUrl: null,
  age: null,
  gender: null,
  isAssignedToMe: true,
);

CompatibilityCase _case({
  required int id,
  required CompatibilityCaseStage stage,
  FormalRequestStatus? formal,
  String my = 'أحمد',
  String other = 'سارة',
}) {
  return CompatibilityCase(
    caseId: id,
    myUser: _user(my),
    otherUser: _user(other),
    likeAcceptedAt: null,
    stage: stage,
    photoExchange: null,
    formalRequest: formal == null
        ? null
        : CaseFormalRequest(id: id, status: formal),
    chat: _chat,
    canUpdateFormalRequestStatus: true,
    hasMyNote: false,
  );
}

void main() {
  final like = _case(id: 1, stage: CompatibilityCaseStage.likeAccepted);
  final photo = _case(
    id: 2,
    stage: CompatibilityCaseStage.photoExchangePending,
  );
  final waiting = _case(
    id: 3,
    stage: CompatibilityCaseStage.photoExchangeAccepted,
    formal: FormalRequestStatus.waitingForParentAppointment,
  );
  final closed = _case(
    id: 4,
    stage: CompatibilityCaseStage.photoExchangeAccepted,
    formal: FormalRequestStatus.compatibilityClosed,
    my: 'خالد',
    other: 'ليان',
  );
  final completed = _case(
    id: 5,
    stage: CompatibilityCaseStage.photoExchangeAccepted,
    formal: FormalRequestStatus.successfullyClosed,
  );
  group('caseStageOf', () {
    test('maps each case to its canonical stage', () {
      expect(caseStageOf(like), CaseStage.likeAccepted);
      expect(caseStageOf(photo), CaseStage.photoExchange);
      expect(caseStageOf(waiting), CaseStage.waitingAppointment);
      // closed/cancelled anchor to the first formal stage.
      expect(caseStageOf(closed), CaseStage.waitingAppointment);
      expect(caseStageOf(completed), CaseStage.completed);
    });
  });

  group('MatchmakerCasesFilter', () {
    test('default sends no server constraints', () {
      const f = MatchmakerCasesFilter();
      expect(f.isActive, isFalse);
      expect(f.stage, isNull);
      expect(f.activeFormalRequest, isNull);
    });

    test('stage and formal-request constraints are independent', () {
      const f = MatchmakerCasesFilter(
        stage: CompatibilityCaseStage.photoExchangeRejected,
        activeFormalRequest: true,
      );
      expect(f.isActive, isTrue);
      expect(f.stage?.apiValue, 3);
      expect(f.activeFormalRequest, isTrue);
    });

    test('all five server stage values map exactly to 0..4', () {
      expect(
        CompatibilityCaseStage.values
            .where((stage) => stage != CompatibilityCaseStage.unknown)
            .map((stage) => stage.apiValue),
        [0, 1, 2, 3, 4],
      );
    });
  });
}
