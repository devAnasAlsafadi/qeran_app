import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/chat/domain/entities/chat_message.dart';
import 'package:qeran/features/chat/domain/entities/message_send_status.dart';
import 'package:qeran/features/chat/domain/entities/send_text_outcome.dart';
import 'package:qeran/features/chat/domain/ports/chat_realtime_port.dart';
import 'package:qeran/features/chat/domain/usecases/get_conversation_messages_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/mark_conversation_as_read_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/send_text_message_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/share_profile_usecase.dart';
import 'package:qeran/features/chat/presentation/blocs/conversation_cubit.dart';
import 'package:qeran/features/chat/presentation/screens/chat_composer_send.dart';

class _MockSend extends Mock implements SendTextMessageUseCase {}

class _FakeGet extends Fake implements GetConversationMessagesUseCase {}

class _FakeMark extends Fake implements MarkConversationAsReadUseCase {}

class _FakeShare extends Fake implements ShareProfileUseCase {}

class _FakePort extends Fake implements ChatRealtimePort {}

void main() {
  late _MockSend send;
  late ConversationCubit cubit;

  void answer(SendTextOutcome outcome) => when(
    () => send(conversationId: 42, content: any(named: 'content')),
  ).thenAnswer((_) async => Right<Failure, SendTextOutcome>(outcome));

  setUp(() {
    send = _MockSend();
    cubit = ConversationCubit(
      conversationId: 42,
      myUserId: 'me',
      getMessages: _FakeGet(),
      markAsRead: _FakeMark(),
      sendText: send,
      shareProfile: _FakeShare(),
      realtimePort: _FakePort(),
    );
  });

  tearDown(() => cubit.close());

  test('a delivered message has left the composer', () async {
    answer(
      SendTextSuccess(
        message: ChatMessage(
          serverId: 1,
          clientTempId: null,
          conversationId: 42,
          senderId: 'me',
          senderName: 'me',
          content: 'Hello',
          sharedProfile: null,
          isRead: false,
          sentAt: DateTime.utc(2026, 9, 30),
          status: MessageSendStatus.sent,
        ),
      ),
    );

    expect(await sendFromComposer(cubit, 'Hello'), isTrue);
  });

  test('a server rate limit gives the text back', () async {
    answer(const SendTextRateLimited(serverMessage: 'too many'));

    expect(await sendFromComposer(cubit, 'Hello'), isFalse);
  });

  // The cooldown the first 429 set refuses the next send before any request.
  test('the local cooldown gives the text back too', () async {
    answer(const SendTextRateLimited(serverMessage: 'too many'));
    await sendFromComposer(cubit, 'First');

    expect(await sendFromComposer(cubit, 'Second'), isFalse);
  });

  // A failed send stays in the list as a bubble with its own retry; putting
  // the text back as well would offer to send it twice.
  test('a failed send is not given back', () async {
    answer(const SendTextFailure(serverMessage: 'boom', errorCode: 'X'));

    expect(await sendFromComposer(cubit, 'Hello'), isTrue);
  });
}
