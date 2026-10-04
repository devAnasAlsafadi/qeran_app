import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/features/profile/data/models/my_profile_model.dart';
import 'package:qeran/features/profile/domain/entities/my_profile.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';
import 'package:qeran/features/profile/domain/usecases/get_my_profile_usecase.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_state.dart';

class _MockGetMyProfile extends Mock implements GetMyProfileUseCase {}

MyProfile _profile({bool? accepted, String name = 'سارة'}) => MyProfile(
  id: 'u-1',
  name: name,
  email: null,
  gender: 'Female',
  birthDate: null,
  age: 28,
  profileStatus: ProfileStatus.visible,
  hasAnsweredQuestions: true,
  profileImage: null,
  images: const [],
  placements: const [],
  communityGuidelinesAccepted: accepted,
);

/// D7's mirror: whether the member has accepted the current Community
/// guidelines, as `GET /api/profile` says — kept by the app's gate so the
/// composer can ask once, before the first comment.
void main() {
  group('the profile payload', () {
    MyProfile parse(Map<String, dynamic> extra) =>
        MyProfileModel.fromJson({'userId': 'u-1', ...extra}).toEntity();

    test('carries the flag either way', () {
      expect(
        parse({
          'communityGuidelinesAccepted': true,
        }).communityGuidelinesAccepted,
        isTrue,
      );
      expect(
        parse({
          'communityGuidelinesAccepted': false,
        }).communityGuidelinesAccepted,
        isFalse,
      );
    });

    test('without it, says nothing rather than "not accepted"', () {
      expect(parse({}).communityGuidelinesAccepted, isNull);
    });
  });

  group('the gate', () {
    late _MockGetMyProfile getMyProfile;
    late ProfileGateCubit gate;

    setUp(() {
      getMyProfile = _MockGetMyProfile();
      gate = ProfileGateCubit(getMyProfile: getMyProfile);
    });

    tearDown(() => gate.close());

    bool? accepted() =>
        (gate.state as ProfileGateResolved).communityGuidelinesAccepted;

    test('resolves the flag from the profile it reads', () async {
      when(
        () => getMyProfile(),
      ).thenAnswer((_) async => Right(_profile(accepted: false)));

      await gate.refresh();

      expect(accepted(), isFalse);
    });

    test('a saved name without the flag keeps what was known', () async {
      when(
        () => getMyProfile(),
      ).thenAnswer((_) async => Right(_profile(accepted: true)));
      await gate.refresh();

      gate.applyProfile(_profile(name: 'ديما'));

      expect(accepted(), isTrue);
      expect((gate.state as ProfileGateResolved).name, 'ديما');
    });

    test('a profile that carries the flag wins', () async {
      when(
        () => getMyProfile(),
      ).thenAnswer((_) async => Right(_profile(accepted: true)));
      await gate.refresh();

      gate.applyProfile(_profile(accepted: false));

      expect(accepted(), isFalse);
    });

    test('accepting marks it, keeping everything else', () async {
      when(
        () => getMyProfile(),
      ).thenAnswer((_) async => Right(_profile(accepted: false)));
      await gate.refresh();

      gate.markCommunityGuidelinesAccepted();

      expect(accepted(), isTrue);
      final state = gate.state as ProfileGateResolved;
      expect(state.name, 'سارة');
      expect(state.status, ProfileStatus.visible);
    });

    test('before the profile is known, accepting changes nothing', () {
      gate.markCommunityGuidelinesAccepted();

      expect(gate.state, isA<ProfileGateInitial>());
    });
  });
}
