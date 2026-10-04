import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/profile/domain/entities/my_profile.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';
import 'package:qeran/features/profile/domain/usecases/get_my_profile_usecase.dart';
import 'package:qeran/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:qeran/features/profile/presentation/blocs/name/name_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/name/name_state.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';

class _MockGetMyProfile extends Mock implements GetMyProfileUseCase {}

class _MockUpdateProfile extends Mock implements UpdateProfileUseCase {}

MyProfile _profile({String name = 'مستخدم', String? realName}) => MyProfile(
  id: 'u-1',
  name: name,
  realName: realName,
  isDefaultName: name == 'مستخدم',
  email: 'a@b.c',
  gender: 'Female',
  birthDate: null,
  age: 28,
  profileStatus: ProfileStatus.visible,
  hasAnsweredQuestions: true,
  profileImage: null,
  images: const [],
  placements: const [],
);

const _filtered = CodedServerFailure(
  message: 'الاسم مخالف',
  errorCode: 'CONTENT_NOT_ALLOWED',
);

/// What Community's name step (F1–F3) and the filter (Q10) ask of the name
/// cubit: a display name saved alone, and a refused one kept for the form.
void main() {
  late _MockGetMyProfile getMyProfile;
  late _MockUpdateProfile updateProfile;
  late ProfileGateCubit gate;

  setUp(() {
    getMyProfile = _MockGetMyProfile();
    updateProfile = _MockUpdateProfile();
    gate = ProfileGateCubit(getMyProfile: getMyProfile);
  });

  tearDown(() => gate.close());

  Future<NameCubit> loaded({String? realName}) async {
    when(
      () => getMyProfile(),
    ).thenAnswer((_) async => Right(_profile(realName: realName)));
    final cubit = NameCubit(
      getMyProfile: getMyProfile,
      updateProfile: updateProfile,
      profileGate: gate,
    );
    await cubit.load();
    return cubit;
  }

  void answer(List<Either<Failure, MyProfile>> results) {
    when(
      () => updateProfile(
        displayName: any(named: 'displayName'),
        realName: any(named: 'realName'),
      ),
    ).thenAnswer((_) async => results.removeAt(0));
  }

  test('the display name alone leaves a real name on file alone', () async {
    final cubit = await loaded(realName: 'سارة السالم');
    answer([Right(_profile(name: 'سارة', realName: 'سارة السالم'))]);

    await cubit.save(displayName: 'سارة');

    verify(() => updateProfile(displayName: 'سارة', realName: null)).called(1);
    await cubit.close();
  });

  test('a filtered name is kept for the form — no toast', () async {
    final cubit = await loaded();
    answer([const Left(_filtered)]);

    await cubit.save(displayName: '  اسم مخالف  ');

    expect(cubit.state.filteredName, 'اسم مخالف');
    expect(cubit.state.saving, isFalse);
    expect(cubit.state.event, NameEvent.none);
    expect(cubit.state.eventVersion, 0);
    expect(cubit.state.errorMessage, isNull);
    await cubit.close();
  });

  test('a name saved afterwards clears it', () async {
    final cubit = await loaded();
    answer([const Left(_filtered), Right(_profile(name: 'سارة'))]);

    await cubit.save(displayName: 'اسم مخالف');
    await cubit.save(displayName: 'سارة');

    expect(cubit.state.filteredName, isNull);
    expect(cubit.state.event, NameEvent.saved);
    await cubit.close();
  });

  test('any other refusal is still a toast with the server\'s words', () async {
    final cubit = await loaded();
    answer([
      const Left(
        CodedServerFailure(
          message: 'اسم غير صالح',
          errorCode: 'VALIDATION_ERROR',
        ),
      ),
    ]);

    await cubit.save(displayName: 'سارة');

    expect(cubit.state.event, NameEvent.saveFailed);
    expect(cubit.state.errorMessage, 'اسم غير صالح');
    expect(cubit.state.filteredName, isNull);
    await cubit.close();
  });
}
