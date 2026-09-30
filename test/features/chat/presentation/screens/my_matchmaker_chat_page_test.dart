import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/theme/qeran_system_bars.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/chat/domain/entities/chat_message.dart';
import 'package:qeran/features/chat/domain/entities/chat_messages_page.dart';
import 'package:qeran/features/chat/domain/entities/matchmaker_info.dart';
import 'package:qeran/features/chat/domain/entities/messages_read_event.dart';
import 'package:qeran/features/chat/domain/entities/my_matchmaker_outcome.dart';
import 'package:qeran/features/chat/domain/entities/realtime_status.dart';
import 'package:qeran/features/chat/domain/ports/chat_realtime_port.dart';
import 'package:qeran/features/chat/domain/usecases/get_conversation_messages_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/get_my_matchmaker_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/mark_conversation_as_read_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/send_text_message_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/share_profile_usecase.dart';
import 'package:qeran/features/chat/presentation/blocs/chat_entry_cubit.dart';
import 'package:qeran/features/chat/presentation/blocs/conversation_cubit.dart';
import 'package:qeran/features/chat/presentation/screens/chat_conversation_screen.dart';
import 'package:qeran/features/chat/presentation/screens/my_matchmaker_chat_page.dart';
import 'package:qeran/features/chat/presentation/widgets/chat_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Strings render as their keys, so the assertions name the key they expect.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

const _huda = MatchmakerInfo(
  matchmakerId: 'mm-1',
  name: 'Huda',
  profileImageUrl: null,
  conversationId: 42,
);

class _FakeGetMyMatchmaker extends Fake implements GetMyMatchmakerUseCase {
  _FakeGetMyMatchmaker(this.result);
  final Future<Either<Failure, MyMatchmakerOutcome>> result;
  @override
  Future<Either<Failure, MyMatchmakerOutcome>> call() => result;
}

class _EmptyConversation extends Fake
    implements GetConversationMessagesUseCase {
  @override
  Future<Either<Failure, ChatMessagesPage>> call({
    required int conversationId,
    required int page,
    required int pageSize,
  }) async => const Right(
    ChatMessagesPage(
      messages: [],
      totalCount: 0,
      pageNumber: 1,
      pageSize: 30,
      totalPages: 1,
    ),
  );
}

class _MockMark extends Mock implements MarkConversationAsReadUseCase {}

class _FakeSend extends Fake implements SendTextMessageUseCase {}

class _FakeShare extends Fake implements ShareProfileUseCase {}

class _QuietPort extends Fake implements ChatRealtimePort {
  @override
  RealtimeStatus get status => RealtimeStatus.disconnected;
  @override
  Stream<RealtimeStatus> get statusStream => const Stream.empty();
  @override
  Stream<ChatMessage> get incomingMessages => const Stream.empty();
  @override
  Stream<MessagesReadEvent> get messagesRead => const Stream.empty();
}

void _register(Future<Either<Failure, MyMatchmakerOutcome>> entry) {
  final mark = _MockMark();
  when(() => mark(any())).thenAnswer((_) async => const Right(unit));
  sl.registerFactory(
    () => ChatEntryCubit(getMyMatchmaker: _FakeGetMyMatchmaker(entry)),
  );
  sl.registerFactoryParam<ConversationCubit, int, String>(
    (id, me) => ConversationCubit(
      conversationId: id,
      myUserId: me,
      getMessages: _EmptyConversation(),
      markAsRead: mark,
      sendText: _FakeSend(),
      shareProfile: _FakeShare(),
      realtimePort: _QuietPort(),
    ),
  );
}

Widget _app(Widget home) => EasyLocalization(
  supportedLocales: const [Locale('en')],
  path: 'assets/translations',
  assetLoader: const _StubAssetLoader(),
  child: Builder(
    builder: (ctx) => MaterialApp(
      locale: ctx.locale,
      supportedLocales: ctx.supportedLocales,
      localizationsDelegates: ctx.localizationDelegates,
      home: home,
    ),
  ),
);

/// Opens the page from a screen underneath, the way every caller does.
Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 40, bottom: 34);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _app(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => openMatchmakerChat(context),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  // The loading state animates forever, so pump rather than settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Finder get _back => find.byIcon(Icons.chevron_left_rounded);

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() async => sl.reset());

  final entryStates = <String, Future<Either<Failure, MyMatchmakerOutcome>>>{
    'loading': Completer<Either<Failure, MyMatchmakerOutcome>>().future,
    'being assigned': Future.value(
      const Right(MyMatchmakerNotAssigned(serverMessage: '')),
    ),
    'failure': Future.value(const Left(ServerFailure(message: 'network'))),
  };

  for (final entry in entryStates.entries) {
    testWidgets('${entry.key}: titled, with a back that closes the page', (
      tester,
    ) async {
      _register(entry.value);
      await _open(tester);

      expect(find.text('shell.matchmaker_role'), findsOneWidget);
      await tester.tap(_back);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(MyMatchmakerChatPage), findsNothing);
    });
  }

  testWidgets('the member sees the role under the matchmaker\'s name', (
    tester,
  ) async {
    _register(Future.value(const Right(MyMatchmakerAssigned(info: _huda))));
    await _open(tester);
    await tester.pumpAndSettle();

    expect(find.text('Huda'), findsOneWidget);
    expect(find.text('shell.matchmaker_role'), findsOneWidget);
    expect(find.text('chat.empty_start_with'), findsOneWidget);
    expect(_back, findsOneWidget);
  });

  testWidgets('the matchmaker\'s side has no role line and its own voice', (
    tester,
  ) async {
    _register(Future.value(const Right(MyMatchmakerAssigned(info: _huda))));
    await tester.pumpWidget(
      _app(
        const Scaffold(
          body: ChatConversationScreen(
            info: _huda,
            viewer: ChatViewer.matchmaker,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Huda'), findsOneWidget);
    expect(find.text('shell.matchmaker_role'), findsNothing);
    expect(find.text('chat.empty_start_with_matchmaker'), findsOneWidget);
  });

  // No canvas strip above the header: the paper starts at the top edge.
  testWidgets('the header runs under the status bar', (tester) async {
    _register(Future.value(const Right(MyMatchmakerAssigned(info: _huda))));
    await _open(tester);
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.byType(ChatHeader)).dy, 0);
    expect(tester.getTopLeft(find.text('Huda')).dy, greaterThan(40));
  });

  testWidgets('the page asks for dark status-bar icons', (tester) async {
    _register(Future.value(const Right(MyMatchmakerAssigned(info: _huda))));
    await _open(tester);

    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>).last,
    );
    expect(region.value, QeranSystemBars.darkIcons);
  });
}
