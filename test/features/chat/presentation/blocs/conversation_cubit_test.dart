import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/chat/domain/entities/chat_message.dart';
import 'package:qeran/features/chat/domain/entities/chat_messages_page.dart';
import 'package:qeran/features/chat/domain/entities/message_send_status.dart';
import 'package:qeran/features/chat/domain/entities/messages_read_event.dart';
import 'package:qeran/features/chat/domain/entities/realtime_status.dart';
import 'package:qeran/features/chat/domain/entities/send_text_outcome.dart';
import 'package:qeran/features/chat/domain/entities/share_profile_outcome.dart';
import 'package:qeran/features/chat/domain/ports/chat_realtime_port.dart';
import 'package:qeran/features/chat/domain/usecases/get_conversation_messages_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/mark_conversation_as_read_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/send_text_message_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/share_profile_usecase.dart';
import 'package:qeran/features/chat/presentation/blocs/conversation_cubit.dart';
import 'package:qeran/features/chat/presentation/blocs/conversation_state.dart';

class _MockGet extends Mock implements GetConversationMessagesUseCase {}

class _MockMark extends Mock implements MarkConversationAsReadUseCase {}

class _MockSend extends Mock implements SendTextMessageUseCase {}

class _MockShare extends Mock implements ShareProfileUseCase {}

/// In-memory `ChatRealtimePort` for unit tests. Lets us drive every
/// stream + observe `connect` / `disconnect` calls without spinning
/// up `signalr_netcore`.
class _FakeRealtimePort implements ChatRealtimePort {
  RealtimeStatus _status = RealtimeStatus.disconnected;
  final _statusController = StreamController<RealtimeStatus>.broadcast();
  final _incomingController = StreamController<ChatMessage>.broadcast();
  final _messagesReadController =
      StreamController<MessagesReadEvent>.broadcast();
  int connectCalls = 0;
  int disconnectCalls = 0;

  @override
  RealtimeStatus get status => _status;
  @override
  Stream<RealtimeStatus> get statusStream => _statusController.stream;
  @override
  Stream<ChatMessage> get incomingMessages => _incomingController.stream;
  @override
  Stream<MessagesReadEvent> get messagesRead =>
      _messagesReadController.stream;

  @override
  Future<void> connect({
    required Future<String?> Function() accessTokenProvider,
  }) async {
    connectCalls++;
    setStatus(RealtimeStatus.connecting);
    setStatus(RealtimeStatus.connected);
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    setStatus(RealtimeStatus.disconnected);
  }

  void setStatus(RealtimeStatus s) {
    _status = s;
    if (!_statusController.isClosed) _statusController.add(s);
  }

  void emitIncoming(ChatMessage m) {
    if (!_incomingController.isClosed) _incomingController.add(m);
  }

  void emitMessagesRead(MessagesReadEvent e) {
    if (!_messagesReadController.isClosed) _messagesReadController.add(e);
  }

  Future<void> close() async {
    await _statusController.close();
    await _incomingController.close();
    await _messagesReadController.close();
  }
}

Future<String?> _stubTokenProvider() async => 'stub-token';

ChatMessage _msg({
  required int id,
  required DateTime sentAt,
  bool isRead = true,
  String sender = 'mm',
}) {
  return ChatMessage(
    serverId: id,
    clientTempId: null,
    conversationId: 42,
    senderId: sender,
    senderName: sender,
    content: 'c$id',
    sharedProfile: null,
    isRead: isRead,
    sentAt: sentAt,
    status: MessageSendStatus.sent,
  );
}

ChatMessagesPage _page(List<ChatMessage> msgs, int page, int total) =>
    ChatMessagesPage(
      messages: msgs,
      totalCount: msgs.length,
      pageNumber: page,
      pageSize: 30,
      totalPages: total,
    );

void main() {
  late _MockGet get;
  late _MockMark mark;
  late _MockSend send;
  late _MockShare share;
  late _FakeRealtimePort realtime;
  late ConversationCubit cubit;

  setUp(() {
    get = _MockGet();
    mark = _MockMark();
    send = _MockSend();
    share = _MockShare();
    realtime = _FakeRealtimePort();
    cubit = ConversationCubit(
      conversationId: 42,
      myUserId: 'me',
      getMessages: get,
      markAsRead: mark,
      sendText: send,
      shareProfile: share,
      realtimePort: realtime,
    );
  });

  tearDown(() async {
    await cubit.close();
    await realtime.close();
  });

  test('init success → loaded + hasMore + page=1 + seen ids populated',
      () async {
    final m1 = _msg(id: 105, sentAt: DateTime.utc(2026, 5, 17, 14, 30));
    final m2 = _msg(id: 104, sentAt: DateTime.utc(2026, 5, 17, 14, 20));
    when(() => get(
            conversationId: 42, page: 1, pageSize: any(named: 'pageSize')))
        .thenAnswer((_) async => Right<Failure, ChatMessagesPage>(
              _page([m1, m2], 1, 3),
            ));
    when(() => mark(42)).thenAnswer((_) async => const Right<Failure, Unit>(unit));

    await cubit.init();

    expect(cubit.state.initialStatus, ConversationAsyncStatus.loaded);
    expect(cubit.state.messages, hasLength(2));
    expect(cubit.state.messages.first.serverId, 105,
        reason: 'newest-first ordering preserved');
    expect(cubit.state.hasMore, isTrue);
    expect(cubit.state.currentPage, 1);
    expect(cubit.state.seenServerIds, {105, 104});
  });

  test('init failure → status failure + error key', () async {
    when(() => get(
            conversationId: 42, page: 1, pageSize: any(named: 'pageSize')))
        .thenAnswer(
      (_) async => const Left<Failure, ChatMessagesPage>(
        ServerFailure(message: 'errors.generic'),
      ),
    );
    await cubit.init();
    expect(cubit.state.initialStatus, ConversationAsyncStatus.failure);
    expect(cubit.state.loadErrorKey, 'errors.generic');
  });

  test('init triggers markAsRead only when there are unread inbound msgs',
      () async {
    final allRead = _msg(
        id: 1, sentAt: DateTime.utc(2026, 5, 17, 14), isRead: true);
    when(() => get(
            conversationId: 42, page: 1, pageSize: any(named: 'pageSize')))
        .thenAnswer((_) async => Right<Failure, ChatMessagesPage>(
              _page([allRead], 1, 1),
            ));
    await cubit.init();
    await Future<void>.delayed(Duration.zero);
    verifyNever(() => mark(any()));
  });

  test('init triggers markAsRead when at least one inbound is unread',
      () async {
    final unread = _msg(
        id: 1, sentAt: DateTime.utc(2026, 5, 17, 14), isRead: false);
    when(() => get(
            conversationId: 42, page: 1, pageSize: any(named: 'pageSize')))
        .thenAnswer((_) async => Right<Failure, ChatMessagesPage>(
              _page([unread], 1, 1),
            ));
    when(() => mark(42))
        .thenAnswer((_) async => const Right<Failure, Unit>(unit));
    await cubit.init();
    await Future<void>.delayed(Duration.zero);
    verify(() => mark(42)).called(1);
  });

  test('loadMore success → appends + dedups + advances page', () async {
    final m1 = _msg(id: 105, sentAt: DateTime.utc(2026, 5, 17, 14, 30));
    when(() => get(
            conversationId: 42, page: 1, pageSize: any(named: 'pageSize')))
        .thenAnswer((_) async => Right<Failure, ChatMessagesPage>(
              _page([m1], 1, 2),
            ));
    when(() => mark(42))
        .thenAnswer((_) async => const Right<Failure, Unit>(unit));
    await cubit.init();

    final m0 = _msg(id: 90, sentAt: DateTime.utc(2026, 5, 17, 12));
    when(() => get(
            conversationId: 42, page: 2, pageSize: any(named: 'pageSize')))
        .thenAnswer((_) async => Right<Failure, ChatMessagesPage>(
              _page([m0, m1 /* duplicate */], 2, 2),
            ));

    await cubit.loadMore();
    expect(cubit.state.messages, hasLength(2));
    expect(cubit.state.currentPage, 2);
    expect(cubit.state.hasMore, isFalse);
    expect(cubit.state.seenServerIds, {105, 90});
  });

  test('loadMore failure → paginationFailed flag set; messages preserved',
      () async {
    final m1 = _msg(id: 105, sentAt: DateTime.utc(2026, 5, 17, 14, 30));
    when(() => get(
            conversationId: 42, page: 1, pageSize: any(named: 'pageSize')))
        .thenAnswer((_) async => Right<Failure, ChatMessagesPage>(
              _page([m1], 1, 5),
            ));
    when(() => mark(42))
        .thenAnswer((_) async => const Right<Failure, Unit>(unit));
    await cubit.init();

    when(() => get(
            conversationId: 42, page: 2, pageSize: any(named: 'pageSize')))
        .thenAnswer((_) async =>
            const Left<Failure, ChatMessagesPage>(ServerFailure(message: 'x')));

    await cubit.loadMore();
    expect(cubit.state.paginationFailed, isTrue);
    expect(cubit.state.messages, hasLength(1));
    expect(cubit.state.isPaginating, isFalse);
  });

  test('loadMore is a no-op when hasMore is false', () async {
    final m1 = _msg(id: 1, sentAt: DateTime.utc(2026));
    when(() => get(
            conversationId: 42, page: 1, pageSize: any(named: 'pageSize')))
        .thenAnswer((_) async => Right<Failure, ChatMessagesPage>(
              _page([m1], 1, 1),
            ));
    when(() => mark(42))
        .thenAnswer((_) async => const Right<Failure, Unit>(unit));
    await cubit.init();
    await cubit.loadMore();
    verifyNever(() => get(conversationId: 42, page: 2, pageSize: 30));
  });

  group('sendText (Phase 5)', () {
    test('empty content → validation event, no REST call', () async {
      await cubit.sendText('   ');
      expect(cubit.state.event, ConversationEvent.sendValidationEmpty);
      verifyNever(() =>
          send(conversationId: any(named: 'conversationId'),
              content: any(named: 'content')));
    });

    test('> 2000 chars → tooLong event, no REST call', () async {
      await cubit.sendText('x' * 2001);
      expect(cubit.state.event, ConversationEvent.sendValidationTooLong);
      verifyNever(() =>
          send(conversationId: any(named: 'conversationId'),
              content: any(named: 'content')));
    });

    test('success → inserts server message + seen id', () async {
      final reply = _msg(
        id: 106,
        sentAt: DateTime.utc(2026, 5, 17, 15),
        isRead: false,
        sender: 'me',
      );
      when(() => send(
            conversationId: 42,
            content: any(named: 'content'),
          )).thenAnswer((_) async =>
          Right<Failure, SendTextOutcome>(SendTextSuccess(message: reply)));

      await cubit.sendText('السلام عليكم');

      expect(cubit.state.messages, hasLength(1));
      expect(cubit.state.messages.first.serverId, 106);
      expect(cubit.state.seenServerIds.contains(106), isTrue);
    });

    test('rate limited → cooldown timestamp set + event emitted', () async {
      when(() => send(
            conversationId: 42,
            content: any(named: 'content'),
          )).thenAnswer((_) async =>
          const Right<Failure, SendTextOutcome>(
              SendTextRateLimited(serverMessage: 'too many')));
      await cubit.sendText('a');
      expect(cubit.state.event, ConversationEvent.sendRateLimited);
      expect(cubit.state.sendCooldownUntil, isNotNull);
    });

    test('during cooldown → emits rateLimited without REST call', () async {
      when(() => send(
            conversationId: 42,
            content: any(named: 'content'),
          )).thenAnswer((_) async =>
          const Right<Failure, SendTextOutcome>(
              SendTextRateLimited(serverMessage: 'too many')));
      await cubit.sendText('a');
      clearInteractions(send);
      await cubit.sendText('b');
      verifyNever(() =>
          send(conversationId: any(named: 'conversationId'),
              content: any(named: 'content')));
      expect(cubit.state.event, ConversationEvent.sendRateLimited);
    });

    test('CONVERSATION_NOT_FOUND → typed event', () async {
      when(() => send(
            conversationId: 42,
            content: any(named: 'content'),
          )).thenAnswer((_) async =>
          const Right<Failure, SendTextOutcome>(
              SendTextConversationNotFound(serverMessage: '')));
      await cubit.sendText('a');
      expect(cubit.state.event, ConversationEvent.sendConversationNotFound);
    });

    test('UNAUTHORIZED → typed event', () async {
      when(() => send(
            conversationId: 42,
            content: any(named: 'content'),
          )).thenAnswer((_) async =>
          const Right<Failure, SendTextOutcome>(
              SendTextUnauthorized(serverMessage: '')));
      await cubit.sendText('a');
      expect(cubit.state.event, ConversationEvent.sendUnauthorized);
    });

    test('transport Left(Failure) → generic sendFailure', () async {
      when(() => send(
            conversationId: 42,
            content: any(named: 'content'),
          )).thenAnswer((_) async => const Left<Failure, SendTextOutcome>(
              ServerFailure(message: 'errors.generic')));
      await cubit.sendText('a');
      expect(cubit.state.event, ConversationEvent.sendFailure);
    });
  });

  group('shareProfile (Phase 5)', () {
    test('empty id → validation event, no REST', () async {
      await cubit.shareProfile(' ');
      expect(cubit.state.event, ConversationEvent.shareValidation);
      verifyNever(() => share(
          conversationId: any(named: 'conversationId'),
          sharedUserId: any(named: 'sharedUserId')));
    });

    test('success → inserts + emits shareSuccess', () async {
      final reply = _msg(
        id: 107,
        sentAt: DateTime.utc(2026, 5, 17, 15),
        sender: 'me',
        isRead: false,
      );
      when(() => share(
            conversationId: 42,
            sharedUserId: 'u',
          )).thenAnswer((_) async => Right<Failure, ShareProfileOutcome>(
              ShareProfileSuccess(message: reply)));
      await cubit.shareProfile('u');
      expect(cubit.state.event, ConversationEvent.shareSuccess);
      expect(cubit.state.messages.first.serverId, 107);
    });

    test('PROFILE_NOT_FOUND → typed event', () async {
      when(() => share(
            conversationId: 42,
            sharedUserId: 'u',
          )).thenAnswer((_) async =>
          const Right<Failure, ShareProfileOutcome>(
              ShareProfileNotFound(serverMessage: '')));
      await cubit.shareProfile('u');
      expect(cubit.state.event, ConversationEvent.shareProfileNotFound);
    });

    test('rate limited → cooldown set + event', () async {
      when(() => share(
            conversationId: 42,
            sharedUserId: 'u',
          )).thenAnswer((_) async =>
          const Right<Failure, ShareProfileOutcome>(
              ShareProfileRateLimited(serverMessage: '')));
      await cubit.shareProfile('u');
      expect(cubit.state.event, ConversationEvent.shareRateLimited);
      expect(cubit.state.sendCooldownUntil, isNotNull);
    });
  });

  group('sendText optimistic (Phase 6)', () {
    test('optimistic temp inserted IMMEDIATELY (before REST completes)',
        () async {
      final completer = Completer<Either<Failure, SendTextOutcome>>();
      when(() => send(
            conversationId: 42,
            content: any(named: 'content'),
          )).thenAnswer((_) => completer.future);

      // Kick off the send but don't await it — we want to inspect the
      // intermediate state.
      final pending = cubit.sendText('hello');
      // Yield a microtask so the cubit's pre-REST emit lands.
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.messages, hasLength(1));
      final temp = cubit.state.messages.first;
      expect(temp.serverId, isNull);
      expect(temp.clientTempId, isNotNull);
      expect(temp.status, MessageSendStatus.sending);
      expect(temp.senderId, 'me');
      expect(temp.content, 'hello');

      // Resolve REST and let the cubit reconcile so the test can tear
      // down cleanly.
      final reply = _msg(
        id: 200,
        sentAt: DateTime.utc(2026, 5, 17, 15),
        sender: 'me',
        isRead: false,
      );
      completer.complete(
        Right<Failure, SendTextOutcome>(SendTextSuccess(message: reply)),
      );
      await pending;
    });

    test('success → temp replaced by server message (still single row)',
        () async {
      final reply = _msg(
        id: 201,
        sentAt: DateTime.utc(2026, 5, 17, 15),
        sender: 'me',
        isRead: false,
      );
      when(() => send(
            conversationId: 42,
            content: any(named: 'content'),
          )).thenAnswer((_) async =>
          Right<Failure, SendTextOutcome>(SendTextSuccess(message: reply)));

      await cubit.sendText('hello');

      expect(cubit.state.messages, hasLength(1));
      final m = cubit.state.messages.first;
      expect(m.serverId, 201);
      expect(m.clientTempId, isNull);
      expect(m.status, MessageSendStatus.sent);
      expect(cubit.state.seenServerIds.contains(201), isTrue);
    });

    test('transport failure → temp stays as failed (NOT removed)', () async {
      when(() => send(
            conversationId: 42,
            content: any(named: 'content'),
          )).thenAnswer((_) async => const Left<Failure, SendTextOutcome>(
              ServerFailure(message: 'errors.generic')));

      await cubit.sendText('hello');

      expect(cubit.state.messages, hasLength(1));
      final m = cubit.state.messages.first;
      expect(m.status, MessageSendStatus.failed);
      expect(m.clientTempId, isNotNull);
      expect(cubit.state.event, ConversationEvent.sendFailure);
    });

    test('SendTextFailure outcome → temp marked failed + event', () async {
      when(() => send(
            conversationId: 42,
            content: any(named: 'content'),
          )).thenAnswer((_) async =>
          const Right<Failure, SendTextOutcome>(
              SendTextFailure(serverMessage: 'x', errorCode: 'UNKNOWN')));
      await cubit.sendText('hello');
      expect(cubit.state.messages.first.status, MessageSendStatus.failed);
      expect(cubit.state.event, ConversationEvent.sendFailure);
    });

    test('CONVERSATION_NOT_FOUND outcome → temp marked failed', () async {
      when(() => send(
            conversationId: 42,
            content: any(named: 'content'),
          )).thenAnswer((_) async =>
          const Right<Failure, SendTextOutcome>(
              SendTextConversationNotFound(serverMessage: '')));
      await cubit.sendText('hello');
      expect(cubit.state.messages.first.status, MessageSendStatus.failed);
      expect(cubit.state.event, ConversationEvent.sendConversationNotFound);
    });

    test('UNAUTHORIZED outcome → temp marked failed', () async {
      when(() => send(
            conversationId: 42,
            content: any(named: 'content'),
          )).thenAnswer((_) async =>
          const Right<Failure, SendTextOutcome>(
              SendTextUnauthorized(serverMessage: '')));
      await cubit.sendText('hello');
      expect(cubit.state.messages.first.status, MessageSendStatus.failed);
      expect(cubit.state.event, ConversationEvent.sendUnauthorized);
    });

    test('SendTextRateLimited → temp REMOVED + cooldown set', () async {
      when(() => send(
            conversationId: 42,
            content: any(named: 'content'),
          )).thenAnswer((_) async =>
          const Right<Failure, SendTextOutcome>(
              SendTextRateLimited(serverMessage: '')));
      await cubit.sendText('hello');
      expect(cubit.state.messages, isEmpty,
          reason: 'rate-limited temp is dropped, not left at "sending"');
      expect(cubit.state.sendCooldownUntil, isNotNull);
      expect(cubit.state.event, ConversationEvent.sendRateLimited);
    });

    test('Server SendTextValidationError → temp REMOVED', () async {
      // Server may reject post-local-validation (e.g. backend has a
      // stricter rule). We drop the temp rather than leave it stuck.
      when(() => send(
            conversationId: 42,
            content: any(named: 'content'),
          )).thenAnswer((_) async =>
          const Right<Failure, SendTextOutcome>(
              SendTextValidationError(serverMessage: '')));
      await cubit.sendText('hello');
      expect(cubit.state.messages, isEmpty);
      expect(cubit.state.event, ConversationEvent.sendValidationEmpty);
    });

    test('cubit closed mid-flight → no emit-after-close throw', () async {
      final completer = Completer<Either<Failure, SendTextOutcome>>();
      when(() => send(
            conversationId: 42,
            content: any(named: 'content'),
          )).thenAnswer((_) => completer.future);

      final pending = cubit.sendText('hello');
      await cubit.close();
      completer.complete(
        Right<Failure, SendTextOutcome>(
          SendTextSuccess(
            message: _msg(
              id: 999,
              sentAt: DateTime.utc(2026),
              sender: 'me',
            ),
          ),
        ),
      );
      await expectLater(pending, completes);
    });
  });

  group('retryFailedSend (Phase 6)', () {
    test('failed temp → retry removes old temp + fires fresh sendText',
        () async {
      // First call fails.
      when(() => send(
            conversationId: 42,
            content: 'hello',
          )).thenAnswer((_) async => const Left<Failure, SendTextOutcome>(
              ServerFailure(message: 'errors.generic')));
      await cubit.sendText('hello');
      expect(cubit.state.messages, hasLength(1));
      final failed = cubit.state.messages.first;
      expect(failed.status, MessageSendStatus.failed);

      // Now stub success for the retry.
      final reply = _msg(
        id: 500,
        sentAt: DateTime.utc(2026, 5, 17, 16),
        sender: 'me',
        isRead: false,
      );
      when(() => send(
            conversationId: 42,
            content: 'hello',
          )).thenAnswer((_) async =>
          Right<Failure, SendTextOutcome>(SendTextSuccess(message: reply)));

      await cubit.retryFailedSend(failed);

      expect(cubit.state.messages, hasLength(1));
      final reconciled = cubit.state.messages.first;
      expect(reconciled.serverId, 500);
      expect(reconciled.status, MessageSendStatus.sent);
      // 2 send calls total: first (failed) + retry (success).
      verify(() => send(conversationId: 42, content: 'hello')).called(2);
    });

    test('retry on a non-failed message is a no-op', () async {
      final sent = _msg(
        id: 100,
        sentAt: DateTime.utc(2026),
        sender: 'me',
      );
      await cubit.retryFailedSend(sent);
      verifyNever(() => send(
          conversationId: any(named: 'conversationId'),
          content: any(named: 'content')));
    });

    test('retry on a failed message lacking clientTempId is a no-op',
        () async {
      final bogus = ChatMessage(
        serverId: null,
        clientTempId: null,
        conversationId: 42,
        senderId: 'me',
        senderName: '',
        content: 'x',
        sharedProfile: null,
        isRead: false,
        sentAt: DateTime.utc(2026),
        status: MessageSendStatus.failed,
      );
      await cubit.retryFailedSend(bogus);
      verifyNever(() => send(
          conversationId: any(named: 'conversationId'),
          content: any(named: 'content')));
    });
  });

  group('dedup invariant (Phase 6)', () {
    test('reconcile drops temp if server id already seen', () async {
      // Pre-load a message with id=300 via the initial fetch path.
      final existing = _msg(
        id: 300,
        sentAt: DateTime.utc(2026, 5, 17, 15),
        sender: 'mm',
        isRead: true,
      );
      when(() => get(
            conversationId: 42,
            page: 1,
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => Right<Failure, ChatMessagesPage>(
              _page([existing], 1, 1)));
      when(() => mark(42))
          .thenAnswer((_) async => const Right<Failure, Unit>(unit));
      await cubit.init();
      expect(cubit.state.seenServerIds.contains(300), isTrue);

      // Now send a message; REST happens to return id=300 (simulates a
      // pathological reconnect-replay race). The temp must be dropped
      // and we must NOT end up with two id=300 rows.
      final duplicate = _msg(
        id: 300,
        sentAt: DateTime.utc(2026, 5, 17, 15),
        sender: 'me',
      );
      when(() => send(
            conversationId: 42,
            content: any(named: 'content'),
          )).thenAnswer((_) async => Right<Failure, SendTextOutcome>(
              SendTextSuccess(message: duplicate)));

      await cubit.sendText('hello');

      expect(cubit.state.messages, hasLength(1),
          reason: 'no duplicate row when serverId collides');
      expect(cubit.state.messages.first.serverId, 300);
    });
  });

  group('realtime wiring (Phase 8)', () {
    /// The shell opens the session before any conversation screen mounts, so
    /// the port is already live by the time this cubit subscribes. Standing in
    /// for `ChatRealtimeHost` here keeps the fixture honest about who connects.
    Future<void> connectAsShell() async {
      await realtime.connect(accessTokenProvider: _stubTokenProvider);
      await Future<void>.delayed(Duration.zero);
    }

    Future<void> stubInitialLoadEmpty() async {
      when(() => get(
            conversationId: 42,
            page: 1,
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => Right<Failure, ChatMessagesPage>(
              _page(const [], 1, 0)));
      when(() => mark(42))
          .thenAnswer((_) async => const Right<Failure, Unit>(unit));
      await connectAsShell();
      await cubit.init();
      await Future<void>.delayed(Duration.zero);
    }

    test('init success subscribes and mirrors the shell-owned status',
        () async {
      await stubInitialLoadEmpty();
      expect(cubit.state.realtimeStatus, RealtimeStatus.connected);
      expect(cubit.state.hasEverBeenConnected, isTrue);
    });

    // The whole point of the shell owning the session: a conversation must
    // never open, close, or churn it. `connect()` tears down any live session
    // before opening a new one, so a stray call here would drop the socket
    // every other tab's badge depends on.
    test('the cubit never touches the session, on any path', () async {
      await stubInitialLoadEmpty();
      await cubit.refresh();
      await Future<void>.delayed(Duration.zero);
      await cubit.close();
      expect(realtime.connectCalls, 1, reason: 'only the shell connected');
      expect(realtime.disconnectCalls, 0);
      cubit = ConversationCubit(
        conversationId: 42,
        myUserId: 'me',
        getMessages: get,
        markAsRead: mark,
        sendText: send,
        shareProfile: share,
        realtimePort: realtime,
      );
    });

    test('init failure leaves the cubit unsubscribed', () async {
      await connectAsShell();
      when(() => get(
            conversationId: 42,
            page: 1,
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => const Left<Failure, ChatMessagesPage>(
              ServerFailure(message: 'errors.generic')));
      await cubit.init();
      await Future<void>.delayed(Duration.zero);
      // A live socket is not enough — without a successful load there is no
      // message list to merge into, so nothing may be consumed.
      realtime.emitIncoming(_msg(
        id: 999,
        sentAt: DateTime.utc(2026, 5, 21, 14, 30),
        sender: 'mm',
      ));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.messages, isEmpty);
      expect(cubit.state.hasEverBeenConnected, isFalse);
    });

    test('incoming message: prepended at top + serverId added to seen set',
        () async {
      await stubInitialLoadEmpty();
      final mm = _msg(
        id: 500,
        sentAt: DateTime.utc(2026, 5, 21, 14, 30),
        sender: 'mm',
        isRead: false,
      );
      when(() => mark(42))
          .thenAnswer((_) async => const Right<Failure, Unit>(unit));
      realtime.emitIncoming(mm);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.messages, hasLength(1));
      expect(cubit.state.messages.first.serverId, 500);
      expect(cubit.state.seenServerIds.contains(500), isTrue);
    });

    test('incoming message: already-seen id is silently dropped (dedup)',
        () async {
      final existing = _msg(
        id: 600,
        sentAt: DateTime.utc(2026, 5, 21, 14, 30),
        sender: 'mm',
      );
      when(() => get(
            conversationId: 42,
            page: 1,
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => Right<Failure, ChatMessagesPage>(
              _page([existing], 1, 1)));
      when(() => mark(42))
          .thenAnswer((_) async => const Right<Failure, Unit>(unit));
      await cubit.init();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.messages, hasLength(1));

      // Same id arrives over SignalR.
      realtime.emitIncoming(existing);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.messages, hasLength(1),
          reason: 'dedup invariant: at most one row per server id');
    });

    test('incoming for wrong conversation is ignored', () async {
      await stubInitialLoadEmpty();
      final foreign = ChatMessage(
        serverId: 999,
        clientTempId: null,
        conversationId: 999, // ≠ 42
        senderId: 'mm',
        senderName: 'mm',
        content: 'wrong',
        sharedProfile: null,
        isRead: false,
        sentAt: DateTime.utc(2026),
        status: MessageSendStatus.sent,
      );
      realtime.emitIncoming(foreign);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.messages, isEmpty);
    });

    test('reconnecting → connected transition fires page=1 catch-up',
        () async {
      // Initial load returns one message (id=700).
      final initial = _msg(
        id: 700,
        sentAt: DateTime.utc(2026, 5, 21, 14, 30),
        sender: 'mm',
      );
      when(() => get(
            conversationId: 42,
            page: 1,
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => Right<Failure, ChatMessagesPage>(
              _page([initial], 1, 1)));
      when(() => mark(42))
          .thenAnswer((_) async => const Right<Failure, Unit>(unit));
      // The catch-up rule only arms once the socket has been up at least
      // once, and it is the shell that puts it up.
      await connectAsShell();
      await cubit.init();
      await Future<void>.delayed(Duration.zero);

      // Catch-up after reconnect returns one extra row (id=701).
      final caughtUp = _msg(
        id: 701,
        sentAt: DateTime.utc(2026, 5, 21, 14, 45),
        sender: 'mm',
      );
      when(() => get(
            conversationId: 42,
            page: 1,
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => Right<Failure, ChatMessagesPage>(
              _page([caughtUp, initial], 1, 1)));

      realtime.setStatus(RealtimeStatus.reconnecting);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.realtimeStatus, RealtimeStatus.reconnecting);

      realtime.setStatus(RealtimeStatus.connected);
      await Future<void>.delayed(Duration.zero);
      // Catch-up merges by id — both rows present, no duplicates.
      expect(cubit.state.messages, hasLength(2));
      expect(cubit.state.seenServerIds, {700, 701});
    });

    test('close cancels subscriptions and leaves the session up', () async {
      await stubInitialLoadEmpty();
      await cubit.close();
      expect(realtime.disconnectCalls, 0,
          reason: 'leaving a conversation must not close the shell session');
      // The subscriptions are gone, so a later event reaches nobody.
      realtime.emitIncoming(_msg(
        id: 1234,
        sentAt: DateTime.utc(2026, 5, 21, 14, 30),
        sender: 'mm',
      ));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.messages, isEmpty);
      // Re-create a fresh cubit so the test-suite's tearDown can call
      // close() again without throwing on a closed bloc.
      cubit = ConversationCubit(
        conversationId: 42,
        myUserId: 'me',
        getMessages: get,
        markAsRead: mark,
        sendText: send,
        shareProfile: share,
        realtimePort: realtime,
      );
    });
  });

  group('MessagesRead handling (Phase 9)', () {
    /// Loads an initial state with one outgoing (mine, unread) + one
    /// incoming (theirs, read) message, with realtime wired.
    Future<void> primeMixedState() async {
      final mine = _msg(
        id: 800,
        sentAt: DateTime.utc(2026, 5, 21, 14, 30),
        sender: 'me',
        isRead: false,
      );
      final theirs = _msg(
        id: 799,
        sentAt: DateTime.utc(2026, 5, 21, 14, 25),
        sender: 'mm',
        isRead: true,
      );
      when(() => get(
            conversationId: 42,
            page: 1,
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => Right<Failure, ChatMessagesPage>(
              _page([mine, theirs], 1, 1)));
      when(() => mark(42))
          .thenAnswer((_) async => const Right<Failure, Unit>(unit));
      await cubit.init();
      await Future<void>.delayed(Duration.zero);
    }

    test('event from matchmaker flips outgoing isRead → true', () async {
      await primeMixedState();
      // Pre-condition: my message starts unread.
      expect(
          cubit.state.messages.firstWhere((m) => m.senderId == 'me').isRead,
          isFalse);

      realtime.emitMessagesRead(MessagesReadEvent(
        conversationId: 42,
        readByUserId: 'mm',
        readAt: DateTime.utc(2026, 5, 21, 14, 35),
      ));
      await Future<void>.delayed(Duration.zero);

      // My message is now read.
      expect(
          cubit.state.messages.firstWhere((m) => m.senderId == 'me').isRead,
          isTrue);
    });

    test('incoming message isRead is NOT touched', () async {
      await primeMixedState();
      realtime.emitMessagesRead(MessagesReadEvent(
        conversationId: 42,
        readByUserId: 'mm',
        readAt: DateTime.utc(2026, 5, 21, 14, 35),
      ));
      await Future<void>.delayed(Duration.zero);
      // Their message (already read) stays read; structure preserved.
      final theirs = cubit.state.messages.firstWhere((m) => m.senderId == 'mm');
      expect(theirs.isRead, isTrue);
      expect(theirs.serverId, 799);
    });

    test('self-read event is ignored', () async {
      await primeMixedState();
      // If somehow the server echoes our own MarkAsRead back to us,
      // do NOT mutate state.
      realtime.emitMessagesRead(MessagesReadEvent(
        conversationId: 42,
        readByUserId: 'me',
        readAt: DateTime.utc(2026, 5, 21, 14, 35),
      ));
      await Future<void>.delayed(Duration.zero);
      expect(
          cubit.state.messages.firstWhere((m) => m.senderId == 'me').isRead,
          isFalse);
    });

    test('event for a different conversation is ignored', () async {
      await primeMixedState();
      realtime.emitMessagesRead(MessagesReadEvent(
        conversationId: 999, // ≠ 42
        readByUserId: 'mm',
        readAt: DateTime.utc(2026, 5, 21, 14, 35),
      ));
      await Future<void>.delayed(Duration.zero);
      expect(
          cubit.state.messages.firstWhere((m) => m.senderId == 'me').isRead,
          isFalse);
    });

    test('no-op when there are no unread outgoing messages', () async {
      // All-read state: prime with one outgoing message already read.
      final mine = _msg(
        id: 900,
        sentAt: DateTime.utc(2026, 5, 21, 14, 30),
        sender: 'me',
        isRead: true,
      );
      when(() => get(
            conversationId: 42,
            page: 1,
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => Right<Failure, ChatMessagesPage>(
              _page([mine], 1, 1)));
      when(() => mark(42))
          .thenAnswer((_) async => const Right<Failure, Unit>(unit));
      await cubit.init();
      await Future<void>.delayed(Duration.zero);

      final preMessages = cubit.state.messages;
      realtime.emitMessagesRead(MessagesReadEvent(
        conversationId: 42,
        readByUserId: 'mm',
        readAt: DateTime.utc(2026, 5, 21, 14, 35),
      ));
      await Future<void>.delayed(Duration.zero);
      // Identity: no emit means same list instance.
      expect(identical(cubit.state.messages, preMessages), isTrue);
    });
  });
}
