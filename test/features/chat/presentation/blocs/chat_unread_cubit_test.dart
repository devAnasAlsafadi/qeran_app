import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/chat/domain/entities/conversation.dart';
import 'package:qeran/features/chat/domain/entities/conversation_type.dart';
import 'package:qeran/features/chat/domain/repositories/chat_repository.dart';
import 'package:qeran/features/chat/domain/usecases/get_conversations_usecase.dart';
import 'package:qeran/features/chat/presentation/blocs/chat_unread_cubit.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

Conversation _conversation(int id, int unread) => Conversation(
  id: id,
  otherParticipantId: 'matchmaker-$id',
  otherParticipantName: 'Matchmaker',
  otherParticipantImageUrl: null,
  otherParticipantImageBlurred: false,
  type: ConversationType.userToMatchmaker,
  lastMessage: null,
  lastMessageAt: null,
  unreadCount: unread,
);

void main() {
  late _MockChatRepository repository;
  late ChatUnreadCubit cubit;

  setUp(() {
    repository = _MockChatRepository();
    cubit = ChatUnreadCubit(
      getConversations: GetConversationsUseCase(repository),
    );
  });

  tearDown(() => cubit.close());

  test('refresh sums server unread counts', () async {
    when(() => repository.getConversations()).thenAnswer(
      (_) async => Right([_conversation(1, 2), _conversation(2, 3)]),
    );

    await cubit.refresh();

    expect(cubit.state, 5);
  });

  test('clear removes the badge optimistically', () async {
    when(
      () => repository.getConversations(),
    ).thenAnswer((_) async => Right([_conversation(1, 4)]));
    await cubit.refresh();

    cubit.clear();

    expect(cubit.state, 0);
  });

  test('refresh failure keeps the last known unread count', () async {
    when(
      () => repository.getConversations(),
    ).thenAnswer((_) async => Right([_conversation(1, 4)]));
    await cubit.refresh();
    when(
      () => repository.getConversations(),
    ).thenAnswer((_) async => const Left(ServerFailure(message: 'network')));

    await cubit.refresh();

    expect(cubit.state, 4);
  });
}
