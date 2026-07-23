import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/profile/domain/entities/my_profile.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';
import 'package:qeran/features/profile/domain/usecases/get_my_profile_usecase.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_state.dart';

class _MockGetMyProfile extends Mock implements GetMyProfileUseCase {}

MyProfile _profile(String id, ProfileStatus status) => MyProfile(
  id: id,
  name: id,
  email: '$id@example.com',
  gender: '',
  birthDate: null,
  age: 0,
  profileStatus: status,
  hasAnsweredQuestions: true,
  profileImage: null,
  images: const [],
  placements: const [],
);

void main() {
  late _MockGetMyProfile getMyProfile;
  late ProfileGateCubit cubit;

  setUp(() {
    getMyProfile = _MockGetMyProfile();
    cubit = ProfileGateCubit(getMyProfile: getMyProfile);
  });

  tearDown(() => cubit.close());

  test('refresh replaces a previous account pending status', () async {
    when(() => getMyProfile()).thenAnswer(
      (_) async => Right(_profile('pending-user', ProfileStatus.pendingReview)),
    );
    await cubit.refresh();
    expect(cubit.isGated, isTrue);

    when(() => getMyProfile()).thenAnswer(
      (_) async => Right(_profile('approved-user', ProfileStatus.visible)),
    );
    await cubit.refresh();

    expect(cubit.state, isA<ProfileGateResolved>());
    expect(cubit.status, ProfileStatus.visible);
    expect(cubit.isGated, isFalse);
    verify(() => getMyProfile()).called(2);
  });

  test('an old account response cannot overwrite the newer session', () async {
    final oldRequest = Completer<Either<Failure, MyProfile>>();
    final newRequest = Completer<Either<Failure, MyProfile>>();
    var callCount = 0;
    when(() => getMyProfile()).thenAnswer(
      (_) => callCount++ == 0 ? oldRequest.future : newRequest.future,
    );

    final firstRefresh = cubit.refresh();
    final secondRefresh = cubit.refresh();

    newRequest.complete(
      Right(_profile('approved-user', ProfileStatus.visible)),
    );
    await secondRefresh;
    oldRequest.complete(
      Right(_profile('pending-user', ProfileStatus.pendingReview)),
    );
    await firstRefresh;

    expect(cubit.status, ProfileStatus.visible);
    expect(cubit.isGated, isFalse);
  });

  test(
    'an unknown wire status fails open instead of appearing pending',
    () async {
      when(
        () => getMyProfile(),
      ).thenAnswer((_) async => Right(_profile('user', ProfileStatus.unknown)));

      await cubit.refresh();

      expect(cubit.status, ProfileStatus.unknown);
      expect(cubit.isGated, isFalse);
    },
  );
}
