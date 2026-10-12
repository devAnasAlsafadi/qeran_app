import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:qeran/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:qeran/features/chat/domain/entities/matchmaker_info.dart';
import 'package:qeran/features/chat/domain/usecases/get_my_matchmaker_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/watch_my_matchmaker_usecase.dart';
import 'package:qeran/features/chat/presentation/blocs/chat_entry_cubit.dart';
import 'package:qeran/features/chat/presentation/blocs/chat_entry_state.dart';
import 'package:qeran/features/chat/presentation/blocs/my_matchmaker_cubit.dart';
import 'package:qeran/features/chat/presentation/blocs/my_matchmaker_state.dart';

class _MockApi extends Mock implements ApiConsumer {}

const _huda = MatchmakerInfo(
  matchmakerId: 'm1',
  name: 'Huda',
  profileImageUrl: null,
  conversationId: 9,
);

/// A member whose matchmaker was deleted is back to waiting for one, exactly
/// as a member never assigned: the bar says «جاري التعيين» and the chat
/// «جاري تعيين خطّابتك» — never her old name, never an error. From the HTTP
/// answer up, over one repository, as the app wires it.
void main() {
  late _MockApi api;
  late MyMatchmakerCubit bar;
  late ChatEntryCubit chat;

  void serverAnswers(Object? Function() answer) =>
      when(() => api.getRaw(any())).thenAnswer((_) async => answer());

  setUp(() async {
    api = _MockApi();
    final repository = ChatRepositoryImpl(
      ChatRemoteDataSourceImpl(apiConsumer: api),
    );
    final getMyMatchmaker = GetMyMatchmakerUseCase(repository);
    bar = MyMatchmakerCubit(
      getMyMatchmaker: getMyMatchmaker,
      watchMyMatchmaker: WatchMyMatchmakerUseCase(repository),
    );
    chat = ChatEntryCubit(getMyMatchmaker: getMyMatchmaker);
    serverAnswers(
      () => {
        'status': 1,
        'data': {
          'matchmakerId': 'm1',
          'name': 'Huda',
          'profileImageUrl': null,
          'conversationId': 9,
        },
      },
    );
    await bar.refresh();
    expect(bar.state, const MyMatchmakerKnown(_huda));
  });

  tearDown(() async {
    await chat.close();
    await bar.close();
  });

  test('inside a 200 envelope: the chat waits, the bar lets her go', () async {
    serverAnswers(
      () => {
        'status': 0,
        'message': 'Matchmaker not found',
        'errorCode': 'MATCHMAKER_NOT_FOUND',
        'data': null,
      },
    );

    await chat.load();
    await pumpEventQueue();

    expect(chat.state, const ChatEntryNoMatchmaker());
    expect(bar.state, const MyMatchmakerNone());
  });

  test('as a refusal: the bar lets her go, the chat waits', () async {
    when(() => api.getRaw(any())).thenThrow(
      CodedServerException(
        message: 'Matchmaker not found',
        errorCode: 'MATCHMAKER_NOT_FOUND',
      ),
    );

    await bar.refresh();
    expect(bar.state, const MyMatchmakerNone());

    await chat.load();
    expect(chat.state, const ChatEntryNoMatchmaker());
  });
}
