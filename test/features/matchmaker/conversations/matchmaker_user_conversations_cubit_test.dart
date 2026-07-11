import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/matchmaker/conversations/domain/entities/matchmaker_conversation.dart';
import 'package:qeran/features/matchmaker/conversations/domain/entities/matchmaker_conversations_page.dart';
import 'package:qeran/features/matchmaker/conversations/domain/repositories/matchmaker_conversations_repository.dart';
import 'package:qeran/features/matchmaker/conversations/domain/usecases/get_user_conversations_usecase.dart';
import 'package:qeran/features/matchmaker/conversations/presentation/blocs/matchmaker_user_conversations_cubit.dart';
import 'package:qeran/features/matchmaker/shared/domain/entities/compatibility_case_update.dart';
import 'package:qeran/features/matchmaker/shared/domain/entities/matchmaker_realtime_status.dart';
import 'package:qeran/features/matchmaker/shared/domain/entities/received_chat_message.dart';
import 'package:qeran/features/matchmaker/shared/domain/ports/matchmaker_realtime_port.dart';

MatchmakerConversation _conv(int id, {int unread = 0}) => MatchmakerConversation(
      userId: 'u$id',
      fullName: 'User $id',
      profileImageUrl: null,
      conversationId: id,
      lastMessageAt: DateTime.fromMillisecondsSinceEpoch(id * 1000),
      lastMessagePreview: 'hi',
      unreadCount: unread,
    );

/// Counts fetches so a re-fetch is observable.
class _FakeRepo implements MatchmakerConversationsRepository {
  int fetchCount = 0;

  @override
  Future<Either<Failure, MatchmakerConversationsPage>> getUserConversations({
    required int page,
    required int pageSize,
  }) async {
    fetchCount++;
    return Right(MatchmakerConversationsPage(
      items: [_conv(2, unread: 3), _conv(1, unread: 0)],
      pageNumber: 1,
      totalPages: 1,
    ));
  }

  @override
  Future<Either<Failure, int>> openChatWithUser(String userId) async =>
      const Right(0);
}

class _FakePort implements MatchmakerRealtimePort {
  @override
  MatchmakerRealtimeStatus get status => MatchmakerRealtimeStatus.disconnected;
  @override
  Stream<MatchmakerRealtimeStatus> get statusStream => const Stream.empty();
  @override
  Stream<CompatibilityCaseUpdate> get caseUpdates => const Stream.empty();
  @override
  Stream<ReceivedChatMessage> get incomingMessages => const Stream.empty();
  @override
  Future<void> connect() async {}
  @override
  Future<void> disconnect() async {}
}

void main() {
  late _FakeRepo repo;
  late MatchmakerUserConversationsCubit cubit;

  setUp(() {
    repo = _FakeRepo();
    cubit = MatchmakerUserConversationsCubit(
      getConversations: GetUserConversationsUseCase(repo),
      realtimePort: _FakePort(),
      myUserId: 'me',
    );
  });

  tearDown(() => cubit.close());

  test('markConversationRead clears one row in place WITHOUT a re-fetch',
      () async {
    await cubit.loadFirst();
    expect(repo.fetchCount, 1);
    expect(cubit.state.items.firstWhere((c) => c.conversationId == 2).unreadCount,
        3);

    cubit.markConversationRead(2);

    // The badge cleared locally...
    expect(cubit.state.items.firstWhere((c) => c.conversationId == 2).unreadCount,
        0);
    // ...and NO network re-fetch happened (this is the bug fix).
    expect(repo.fetchCount, 1);
    // Other rows and list length are untouched.
    expect(cubit.state.items, hasLength(2));
  });

  test('markConversationRead is a no-op for an unknown / already-read id',
      () async {
    await cubit.loadFirst();
    final before = cubit.state;

    cubit.markConversationRead(999); // unknown
    cubit.markConversationRead(1); // already 0

    expect(identical(cubit.state, before), isTrue);
    expect(repo.fetchCount, 1);
  });
}
