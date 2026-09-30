import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:qeran/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:qeran/features/chat/domain/entities/matchmaker_info.dart';
import 'package:qeran/features/chat/domain/entities/my_matchmaker_outcome.dart';

class _MockDataSource extends Mock implements ChatRemoteDataSource {}

const _huda = MatchmakerInfo(
  matchmakerId: 'm1',
  name: 'Huda',
  profileImageUrl: null,
  conversationId: 9,
);

void main() {
  late _MockDataSource dataSource;
  late ChatRepositoryImpl repository;
  late List<MyMatchmakerOutcome> heard;

  setUp(() {
    dataSource = _MockDataSource();
    repository = ChatRepositoryImpl(dataSource);
    heard = [];
    repository.myMatchmakerAnswers.listen(heard.add);
  });

  Future<void> read(MyMatchmakerOutcome Function() answer) async {
    when(() => dataSource.getMyMatchmaker()).thenAnswer((_) async => answer());
    await repository.getMyMatchmaker();
    await pumpEventQueue();
  }

  test('every answer about who she is goes to the listeners', () async {
    await read(() => const MyMatchmakerAssigned(info: _huda));
    await read(() => const MyMatchmakerNotAssigned(serverMessage: ''));

    expect(heard, [
      isA<MyMatchmakerAssigned>().having((a) => a.info, 'info', _huda),
      isA<MyMatchmakerNotAssigned>(),
    ]);
  });

  test('a failed read tells the listeners nothing', () async {
    await read(
      () => const MyMatchmakerFailure(serverMessage: '', errorCode: 'X'),
    );
    await read(() => throw const OfflineException());

    expect(heard, isEmpty);
  });
}
