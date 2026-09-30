import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:qeran/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:qeran/features/chat/domain/entities/matchmaker_info.dart';
import 'package:qeran/features/chat/domain/entities/my_matchmaker_outcome.dart';
import 'package:qeran/features/chat/domain/usecases/get_my_matchmaker_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/watch_my_matchmaker_usecase.dart';
import 'package:qeran/features/chat/presentation/blocs/chat_entry_cubit.dart';
import 'package:qeran/features/chat/presentation/blocs/chat_entry_state.dart';
import 'package:qeran/features/chat/presentation/blocs/my_matchmaker_cubit.dart';
import 'package:qeran/features/chat/presentation/blocs/my_matchmaker_state.dart';

class _MockDataSource extends Mock implements ChatRemoteDataSource {}

const _huda = MatchmakerInfo(
  matchmakerId: 'm1',
  name: 'Huda',
  profileImageUrl: null,
  conversationId: 9,
);

const _salma = MatchmakerInfo(
  matchmakerId: 'm2',
  name: 'Salma',
  profileImageUrl: null,
  conversationId: 12,
);

/// The top bar's cubit and the chat's, over one repository — as the app
/// wires them. Opening the chat must leave the bar showing whoever the chat
/// loaded, without the bar asking the server itself.
void main() {
  late _MockDataSource server;
  late MyMatchmakerCubit bar;
  late ChatEntryCubit chat;

  void serverSays(MyMatchmakerOutcome Function() answer) =>
      when(() => server.getMyMatchmaker()).thenAnswer((_) async => answer());

  setUp(() {
    server = _MockDataSource();
    final repository = ChatRepositoryImpl(server);
    final getMyMatchmaker = GetMyMatchmakerUseCase(repository);
    bar = MyMatchmakerCubit(
      getMyMatchmaker: getMyMatchmaker,
      watchMyMatchmaker: WatchMyMatchmakerUseCase(repository),
    );
    chat = ChatEntryCubit(getMyMatchmaker: getMyMatchmaker);
  });

  tearDown(() async {
    await chat.close();
    await bar.close();
  });

  test('a matchmaker the chat loads is the one the bar shows', () async {
    serverSays(() => const MyMatchmakerNotAssigned(serverMessage: ''));
    await bar.refresh();
    expect(bar.state, const MyMatchmakerNone());

    serverSays(() => const MyMatchmakerAssigned(info: _huda));
    await chat.load();
    await pumpEventQueue();

    expect(chat.state, const ChatEntryReady(info: _huda));
    expect(bar.state, const MyMatchmakerKnown(_huda));
  });

  test('a reassignment the chat finds reaches the bar', () async {
    serverSays(() => const MyMatchmakerAssigned(info: _huda));
    await bar.refresh();

    serverSays(() => const MyMatchmakerAssigned(info: _salma));
    await chat.load();
    await pumpEventQueue();

    expect(bar.state, const MyMatchmakerKnown(_salma));
    // The bar took the chat's answer; it did not read again.
    verify(() => server.getMyMatchmaker()).called(2);
  });

  test('the bar learns her from the chat after its own read failed', () async {
    serverSays(() => throw const OfflineException());
    await bar.refresh();
    expect(bar.state, const MyMatchmakerUnknown());

    serverSays(() => const MyMatchmakerAssigned(info: _huda));
    await chat.load();
    await pumpEventQueue();

    expect(bar.state, const MyMatchmakerKnown(_huda));
  });

  test('a chat that fails to load leaves the bar as it was', () async {
    serverSays(() => const MyMatchmakerAssigned(info: _huda));
    await bar.refresh();

    serverSays(() => throw const OfflineException());
    await chat.load();
    await pumpEventQueue();

    expect(chat.state, const ChatEntryFailure());
    expect(bar.state, const MyMatchmakerKnown(_huda));
  });
}
