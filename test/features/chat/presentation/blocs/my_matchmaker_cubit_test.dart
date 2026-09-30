import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/chat/domain/entities/matchmaker_info.dart';
import 'package:qeran/features/chat/domain/entities/my_matchmaker_outcome.dart';
import 'package:qeran/features/chat/domain/usecases/get_my_matchmaker_usecase.dart';
import 'package:qeran/features/chat/presentation/blocs/my_matchmaker_cubit.dart';
import 'package:qeran/features/chat/presentation/blocs/my_matchmaker_state.dart';

class _MockGetMyMatchmaker extends Mock implements GetMyMatchmakerUseCase {}

const _huda = MatchmakerInfo(
  matchmakerId: 'm1',
  name: 'Huda',
  profileImageUrl: null,
  conversationId: 9,
);

void main() {
  late _MockGetMyMatchmaker getMyMatchmaker;
  late MyMatchmakerCubit cubit;

  void answer(Either<Failure, MyMatchmakerOutcome> result) =>
      when(() => getMyMatchmaker()).thenAnswer((_) async => result);

  setUp(() {
    getMyMatchmaker = _MockGetMyMatchmaker();
    cubit = MyMatchmakerCubit(getMyMatchmaker: getMyMatchmaker);
  });

  tearDown(() => cubit.close());

  test('starts unknown', () {
    expect(cubit.state, const MyMatchmakerUnknown());
  });

  test('an assigned matchmaker becomes known', () async {
    answer(const Right(MyMatchmakerAssigned(info: _huda)));

    await cubit.refresh();

    expect(cubit.state, const MyMatchmakerKnown(_huda));
  });

  test('no matchmaker yet reads as none', () async {
    answer(const Right(MyMatchmakerNotAssigned(serverMessage: '')));

    await cubit.refresh();

    expect(cubit.state, const MyMatchmakerNone());
  });

  // A re-read runs behind a bar that already shows her; blanking it for the
  // length of a request would flicker on every return to the app.
  test('a refresh emits the answer only, never an interim state', () async {
    answer(const Right(MyMatchmakerAssigned(info: _huda)));
    final first = expectLater(
      cubit.stream,
      emits(const MyMatchmakerKnown(_huda)),
    );

    await cubit.refresh();

    await first;
  });

  test('a failed re-read keeps the matchmaker it already knew', () async {
    answer(const Right(MyMatchmakerAssigned(info: _huda)));
    await cubit.refresh();

    answer(const Left(ServerFailure(message: 'offline')));
    await cubit.refresh();
    expect(cubit.state, const MyMatchmakerKnown(_huda));

    answer(const Right(MyMatchmakerFailure(serverMessage: '', errorCode: 'X')));
    await cubit.refresh();
    expect(cubit.state, const MyMatchmakerKnown(_huda));
  });

  test('a failure before anything is known stays unknown', () async {
    answer(const Left(ServerFailure(message: 'offline')));

    await cubit.refresh();

    expect(cubit.state, const MyMatchmakerUnknown());
  });

  test('a matchmaker assigned later replaces none', () async {
    answer(const Right(MyMatchmakerNotAssigned(serverMessage: '')));
    await cubit.refresh();

    answer(const Right(MyMatchmakerAssigned(info: _huda)));
    await cubit.refresh();

    expect(cubit.state, const MyMatchmakerKnown(_huda));
  });
}
