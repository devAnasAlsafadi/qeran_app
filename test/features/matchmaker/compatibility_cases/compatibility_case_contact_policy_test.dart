import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_chat.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_user.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/compatibility_case.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/compatibility_case_stage.dart';

CaseUser _user(String id, {required bool assigned}) => CaseUser(
  userId: id,
  firstName: id,
  profileImageUrl: null,
  age: null,
  gender: null,
  isAssignedToMe: assigned,
);

CompatibilityCase _case({
  required bool otherAssigned,
  String? otherMatchmakerId,
}) => CompatibilityCase(
  caseId: 1,
  myUser: _user('mine', assigned: true),
  otherUser: _user('other', assigned: otherAssigned),
  likeAcceptedAt: null,
  stage: CompatibilityCaseStage.likeAccepted,
  photoExchange: null,
  formalRequest: null,
  chat: CaseChat(
    myUserConversationId: null,
    otherUserConversationId: null,
    otherMatchmakerId: otherMatchmakerId,
    otherMatchmakerConversationId: null,
    otherMatchmakerName: null,
    otherMatchmakerImageUrl: null,
  ),
  canUpdateFormalRequestStatus: false,
  hasMyNote: false,
);

void main() {
  test('assigned participant exposes direct user chat only', () {
    final item = _case(
      otherAssigned: true,
      otherMatchmakerId: 'stale-colleague-id',
    );

    expect(item.canMessageOtherUser, isTrue);
    expect(item.canMessageOtherMatchmaker, isFalse);
  });

  test('external participant exposes their matchmaker chat only', () {
    final item = _case(otherAssigned: false, otherMatchmakerId: 'colleague-id');

    expect(item.canMessageOtherUser, isFalse);
    expect(item.canMessageOtherMatchmaker, isTrue);
  });

  test(
    'external participant without a matchmaker id exposes neither action',
    () {
      final item = _case(otherAssigned: false);

      expect(item.canMessageOtherUser, isFalse);
      expect(item.canMessageOtherMatchmaker, isFalse);
    },
  );
}
