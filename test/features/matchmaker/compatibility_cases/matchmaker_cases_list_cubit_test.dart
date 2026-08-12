import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_chat.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_formal_request.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_user.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/compatibility_case.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/compatibility_case_stage.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/compatibility_cases_page.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/formal_request_status.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/matchmaker_cases_filter.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/repositories/compatibility_cases_repository.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/usecases/get_compatibility_cases_usecase.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/presentation/blocs/matchmaker_cases_list_cubit.dart';
import 'package:qeran/features/matchmaker/shared/domain/entities/compatibility_case_update.dart';
import 'package:qeran/features/matchmaker/shared/domain/entities/matchmaker_realtime_status.dart';
import 'package:qeran/features/matchmaker/shared/domain/entities/received_chat_message.dart';
import 'package:qeran/features/matchmaker/shared/domain/ports/matchmaker_realtime_port.dart';

class _Repository implements CompatibilityCasesRepository {
  _Repository(this.item);

  final CompatibilityCase item;

  @override
  Future<Either<Failure, CompatibilityCasesPage>> getCases({
    required int page,
    required int pageSize,
    required MatchmakerCasesFilter filter,
  }) async => Right(
    CompatibilityCasesPage(items: [item], pageNumber: 1, totalPages: 1),
  );

  @override
  Future<Either<Failure, String>> updateFormalRequestStatus({
    required int formalRequestId,
    required FormalRequestStatus newStatus,
  }) => throw UnimplementedError();
}

class _RealtimePort implements MatchmakerRealtimePort {
  final updates = StreamController<CompatibilityCaseUpdate>.broadcast();
  final statuses = StreamController<MatchmakerRealtimeStatus>.broadcast();

  @override
  MatchmakerRealtimeStatus get status => MatchmakerRealtimeStatus.disconnected;

  @override
  Stream<CompatibilityCaseUpdate> get caseUpdates => updates.stream;

  @override
  Stream<MatchmakerRealtimeStatus> get statusStream => statuses.stream;

  @override
  Stream<ReceivedChatMessage> get incomingMessages => const Stream.empty();

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  Future<void> dispose() async {
    await updates.close();
    await statuses.close();
  }
}

CaseUser _user(String id) => CaseUser(
  userId: id,
  firstName: id,
  profileImageUrl: null,
  age: null,
  gender: null,
  isAssignedToMe: true,
);

final _case = CompatibilityCase(
  caseId: 7,
  myUser: _user('mine'),
  otherUser: _user('other'),
  likeAcceptedAt: null,
  stage: CompatibilityCaseStage.photoExchangeAccepted,
  photoExchange: null,
  formalRequest: const CaseFormalRequest(
    id: 70,
    status: FormalRequestStatus.parentsVisited,
  ),
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

void main() {
  test(
    'terminal realtime update remains available for completed filter',
    () async {
      final realtime = _RealtimePort();
      final cubit = MatchmakerCasesListCubit(
        getCases: GetCompatibilityCasesUseCase(_Repository(_case)),
        realtimePort: realtime,
      );
      addTearDown(() async {
        await cubit.close();
        await realtime.dispose();
      });

      await cubit.loadFirst();
      realtime.updates.add(
        const CompatibilityCaseUpdate(
          caseId: 7,
          formalRequestId: 70,
          newStatus: 'SuccessfullyClosed',
          newStatusCode: 3,
          updatedAt: null,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.items, hasLength(1));
      expect(
        cubit.state.items.single.formalRequest?.status,
        FormalRequestStatus.successfullyClosed,
      );
    },
  );

  test('permission can be revoked locally after server rejection', () async {
    final realtime = _RealtimePort();
    final cubit = MatchmakerCasesListCubit(
      getCases: GetCompatibilityCasesUseCase(_Repository(_case)),
      realtimePort: realtime,
    );
    addTearDown(() async {
      await cubit.close();
      await realtime.dispose();
    });

    await cubit.loadFirst();
    cubit.markStatusUpdateUnavailable(7);

    expect(cubit.state.items.single.canUpdateFormalRequestStatus, isFalse);
  });
}
