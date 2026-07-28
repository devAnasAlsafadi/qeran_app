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
  final all = [like, photo, waiting, closed, completed];

  List<int> ids(List<CompatibilityCase> cs) => cs.map((c) => c.caseId).toList();

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
    test('الكل (no stage, no name) passes everything', () {
      const f = MatchmakerCasesFilter();
      expect(f.isActive, isFalse);
      expect(ids(f.apply(all)), [1, 2, 3, 4, 5]);
    });

    test('single stage keeps only cases at that stage', () {
      const f = MatchmakerCasesFilter(stage: CaseStage.likeAccepted);
      expect(f.isActive, isTrue);
      expect(ids(f.apply(all)), [1]);
    });

    test('waitingAppointment includes the closed case anchored there', () {
      const f = MatchmakerCasesFilter(stage: CaseStage.waitingAppointment);
      expect(ids(f.apply(all)), [3, 4]);
    });

    test('completed keeps successfully closed cases visible', () {
      const f = MatchmakerCasesFilter(stage: CaseStage.completed);
      expect(ids(f.apply(all)), [5]);
    });

    test('name query matches either participant, case-insensitive', () {
      const f = MatchmakerCasesFilter(nameQuery: 'ليان');
      expect(ids(f.apply(all)), [4]);
    });

    test('stage + name combine (AND)', () {
      const f = MatchmakerCasesFilter(
        stage: CaseStage.waitingAppointment,
        nameQuery: 'خالد',
      );
      expect(ids(f.apply(all)), [4]);
    });
  });
}
