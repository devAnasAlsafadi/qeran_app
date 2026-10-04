import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/presentation/screens/community_name_gate_page.dart';
import 'package:qeran/features/profile/domain/entities/my_profile.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';
import 'package:qeran/features/profile/domain/usecases/get_my_profile_usecase.dart';
import 'package:qeran/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:qeran/features/profile/presentation/blocs/name/name_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';

import 'pushed_step_rig.dart';

class _MockGetMyProfile extends Mock implements GetMyProfileUseCase {}

class _MockUpdateProfile extends Mock implements UpdateProfileUseCase {}

/// The member's profile: the placeholder name unless [name] says otherwise.
MyProfile gateProfile({String name = 'مستخدم', String? realName}) => MyProfile(
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

/// The name step's use cases, scripted, behind the container's NameCubit —
/// the one the page asks for.
class NameGateHarness {
  NameGateHarness({MyProfile? profile}) {
    when(
      () => getMyProfile(),
    ).thenAnswer((_) async => Right(profile ?? gateProfile()));
    sl.registerFactory<NameCubit>(
      () => NameCubit(
        getMyProfile: getMyProfile,
        updateProfile: updateProfile,
        profileGate: gate,
      ),
    );
  }

  final getMyProfile = _MockGetMyProfile();
  final updateProfile = _MockUpdateProfile();
  late final gate = ProfileGateCubit(getMyProfile: getMyProfile);

  /// What the step answered; null while it's open.
  bool? result;

  /// Each save answers with the next of [results].
  void answerSaves(List<Either<Failure, MyProfile>> results) {
    when(
      () => updateProfile(
        displayName: any(named: 'displayName'),
        realName: any(named: 'realName'),
      ),
    ).thenAnswer((_) async => results.removeAt(0));
  }

  Future<void> dispose() async {
    await gate.close();
    await sl.reset();
  }
}

/// Opens the name step in [locale] on a phone [size], as the composer will.
Future<void> openNameGate(
  WidgetTester tester,
  NameGateHarness harness, {
  Locale locale = const Locale('en'),
  Size size = const Size(390, 900),
}) => openPushedStep(
  tester,
  (context) async => harness.result = await openCommunityNameGate(context),
  locale: locale,
  size: size,
);
