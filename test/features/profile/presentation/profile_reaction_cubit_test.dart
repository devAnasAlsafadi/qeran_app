import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/discovery/domain/entities/like_outcome.dart';
import 'package:qeran/features/discovery/domain/usecases/like_profile_usecase.dart';
import 'package:qeran/features/discovery/domain/usecases/pass_profile_usecase.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_reaction/profile_reaction_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_reaction/profile_reaction_state.dart';

class _MockLike extends Mock implements LikeProfileUseCase {}

class _MockPass extends Mock implements PassProfileUseCase {}

class _MockGate extends Mock implements ProfileGateCubit {}

void main() {
  late _MockLike like;
  late _MockPass pass;
  late _MockGate gate;
  late int counterRefreshes;
  late ProfileReactionCubit cubit;

  setUp(() {
    like = _MockLike();
    pass = _MockPass();
    gate = _MockGate();
    counterRefreshes = 0;
    when(() => gate.isGated).thenReturn(false);
    cubit = ProfileReactionCubit(
      likeProfile: like,
      passProfile: pass,
      profileGate: gate,
      onLikeSuccess: () async => counterRefreshes++,
    );
  });

  tearDown(() => cubit.close());

  test(
    'accepted like emits success and refreshes the subscription counter',
    () async {
      when(() => like('candidate')).thenAnswer(
        (_) async =>
            const Right<Failure, LikeOutcome>(LikeAccepted(likeId: '42')),
      );

      await cubit.like('candidate');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.event, ProfileReactionEvent.likeSuccess);
      expect(counterRefreshes, 1);
    },
  );

  test('approval gate blocks the API and emits under-review', () async {
    when(() => gate.isGated).thenReturn(true);

    await cubit.like('candidate');

    expect(cubit.state.event, ProfileReactionEvent.underReview);
    verifyNever(() => like(any()));
  });

  test('pass success emits passSuccess', () async {
    when(
      () => pass('candidate'),
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

    await cubit.pass('candidate');

    expect(cubit.state.event, ProfileReactionEvent.passSuccess);
  });
}
