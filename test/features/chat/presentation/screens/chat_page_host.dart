import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/widgets/connectivity_banner_host.dart';
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
import 'package:qeran/features/chat/presentation/screens/my_matchmaker_chat_page.dart';

/// Strings render as their keys, so the assertions name the key they expect.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

const kHuda = MatchmakerInfo(
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

/// The chat's cubits, with the entry answering [entry] and an empty
/// conversation behind it.
void registerChatPage(Future<Either<Failure, MyMatchmakerOutcome>> entry) {
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

/// The app around [home]. With [offline] set, under the banner host too.
Widget chatApp(Widget home, {bool? offline}) => EasyLocalization(
  supportedLocales: const [Locale('en')],
  path: 'assets/translations',
  assetLoader: const _StubAssetLoader(),
  child: Builder(
    builder: (ctx) => MaterialApp(
      locale: ctx.locale,
      supportedLocales: ctx.supportedLocales,
      localizationsDelegates: ctx.localizationDelegates,
      builder: offline == null
          ? null
          : (_, child) =>
                ConnectivityBannerHost(offline: offline, child: child!),
      home: home,
    ),
  ),
);

/// Opens the page from a screen underneath, the way every caller does.
Future<void> openChatPage(WidgetTester tester, {bool? offline}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 40, bottom: 34);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    chatApp(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => openMatchmakerChat(context),
          child: const Text('open'),
        ),
      ),
      offline: offline,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  // The loading state animates forever, so pump rather than settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}
