import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/chat/domain/entities/matchmaker_info.dart';
import 'package:qeran/features/chat/domain/entities/my_matchmaker_outcome.dart';
import 'package:qeran/features/chat/domain/usecases/get_my_matchmaker_usecase.dart';
import 'package:qeran/features/chat/presentation/blocs/chat_entry_cubit.dart';
import 'package:qeran/features/chat/presentation/blocs/chat_entry_state.dart';

class _MockUseCase extends Mock implements GetMyMatchmakerUseCase {}

const _info = MatchmakerInfo(
  matchmakerId: 'mm',
  name: 'أم محمد',
  profileImageUrl: null,
  conversationId: 42,
);

void main() {
  late _MockUseCase uc;
  late ChatEntryCubit cubit;

  setUp(() {
    uc = _MockUseCase();
    cubit = ChatEntryCubit(getMyMatchmaker: uc);
  });

  tearDown(() => cubit.close());

  test('initial state is ChatEntryInitial', () {
    expect(cubit.state, isA<ChatEntryInitial>());
  });

  test('load assigned → ChatEntryReady carries info', () async {
    when(() => uc()).thenAnswer(
      (_) async => const Right<Failure, MyMatchmakerOutcome>(
        MyMatchmakerAssigned(info: _info),
      ),
    );
    await cubit.load();
    expect(cubit.state, isA<ChatEntryReady>());
    expect((cubit.state as ChatEntryReady).info.conversationId, 42);
  });

  test('load not-assigned → ChatEntryNoMatchmaker', () async {
    when(() => uc()).thenAnswer(
      (_) async => const Right<Failure, MyMatchmakerOutcome>(
        MyMatchmakerNotAssigned(serverMessage: 'no'),
      ),
    );
    await cubit.load();
    expect(cubit.state, isA<ChatEntryNoMatchmaker>());
  });

  test('load failure outcome → ChatEntryFailure', () async {
    when(() => uc()).thenAnswer(
      (_) async => const Right<Failure, MyMatchmakerOutcome>(
        MyMatchmakerFailure(serverMessage: 'oops', errorCode: 'X'),
      ),
    );
    await cubit.load();
    expect(cubit.state, isA<ChatEntryFailure>());
  });

  test('load transport Left(Failure) → ChatEntryFailure', () async {
    when(() => uc()).thenAnswer(
      (_) async => const Left<Failure, MyMatchmakerOutcome>(
        ServerFailure(message: 'errors.generic'),
      ),
    );
    await cubit.load();
    expect(cubit.state, isA<ChatEntryFailure>());
  });

  test('refresh delegates to load', () async {
    when(() => uc()).thenAnswer(
      (_) async => const Right<Failure, MyMatchmakerOutcome>(
        MyMatchmakerAssigned(info: _info),
      ),
    );
    await cubit.refresh();
    verify(() => uc()).called(1);
    expect(cubit.state, isA<ChatEntryReady>());
  });
}
