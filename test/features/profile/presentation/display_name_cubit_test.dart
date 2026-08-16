import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/profile/domain/entities/my_profile.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';
import 'package:qeran/features/profile/domain/usecases/get_my_profile_usecase.dart';
import 'package:qeran/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:qeran/features/profile/presentation/blocs/display_name/display_name_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/display_name/display_name_state.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_state.dart';

class _MockGetMyProfile extends Mock implements GetMyProfileUseCase {}

class _MockUpdateProfile extends Mock implements UpdateProfileUseCase {}

MyProfile _profile({
  String name = 'سارة',
  String? realName,
  bool isDefaultName = false,
}) => MyProfile(
  id: 'u-1',
  name: name,
  realName: realName,
  isDefaultName: isDefaultName,
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

void main() {
  late _MockGetMyProfile getMyProfile;
  late _MockUpdateProfile updateProfile;
  late ProfileGateCubit gate;

  setUp(() {
    getMyProfile = _MockGetMyProfile();
    updateProfile = _MockUpdateProfile();
    // A real gate over a mock use case — the write-back path is what's under
    // test, so a stub would prove nothing.
    gate = ProfileGateCubit(getMyProfile: getMyProfile);
  });

  tearDown(() => gate.close());

  DisplayNameCubit build() => DisplayNameCubit(
    getMyProfile: getMyProfile,
    updateProfile: updateProfile,
    profileGate: gate,
  );

  /// Stubs the write with a fixed result and captures what was actually sent.
  void stubWrite(MyProfile returned) {
    when(
      () => updateProfile(
        displayName: any(named: 'displayName'),
        realName: any(named: 'realName'),
      ),
    ).thenAnswer((_) async => Right(returned));
  }

  /// Both arguments of the single write that happened. Captured in ONE
  /// `verify` — mocktail marks a call verified, so a second `verify` on the
  /// same call would find nothing.
  ({String displayName, String? realName}) capturedWrite() {
    final captured = verify(
      () => updateProfile(
        displayName: captureAny(named: 'displayName'),
        realName: captureAny(named: 'realName'),
      ),
    ).captured;
    return (
      displayName: captured[0] as String,
      realName: captured[1] as String?,
    );
  }

  void verifyNoWrite() => verifyNever(
    () => updateProfile(
      displayName: any(named: 'displayName'),
      realName: any(named: 'realName'),
    ),
  );

  group('load', () {
    test('publishes the profile', () async {
      when(
        () => getMyProfile(),
      ).thenAnswer((_) async => Right(_profile(realName: 'سارة السالم')));
      final cubit = build();

      await cubit.load();

      expect(cubit.state.status, DisplayNameStatus.loaded);
      expect(cubit.state.displayName, 'سارة');
      expect(cubit.state.realName, 'سارة السالم');
      await cubit.close();
    });

    test('a blank realName reads as absent, not as an empty value', () async {
      when(
        () => getMyProfile(),
      ).thenAnswer((_) async => Right(_profile(realName: '   ')));
      final cubit = build();

      await cubit.load();

      expect(cubit.state.realName, isNull);
      await cubit.close();
    });

    test('a failure keeps its message for the error state', () async {
      when(() => getMyProfile()).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'errors.server')),
      );
      final cubit = build();

      await cubit.load();

      expect(cubit.state.status, DisplayNameStatus.failure);
      expect(cubit.state.errorMessage, 'errors.server');
      await cubit.close();
    });
  });

  group('save — what reaches the wire', () {
    test('both names change in one call', () async {
      when(
        () => getMyProfile(),
      ).thenAnswer((_) async => Right(_profile(realName: 'سارة السالم')));
      stubWrite(_profile(name: 'دينا', realName: 'دينا الأحمد'));
      final cubit = build();
      await cubit.load();

      await cubit.save(displayName: 'دينا', realName: 'دينا الأحمد');

      final sent = capturedWrite();
      expect(sent.displayName, 'دينا');
      expect(sent.realName, 'دينا الأحمد');
      await cubit.close();
    });

    test('displayName only — realName is omitted, not blanked', () async {
      // The bug this guards: sending '' here would silently CLEAR a real name
      // the member never touched.
      when(
        () => getMyProfile(),
      ).thenAnswer((_) async => Right(_profile(realName: 'سارة السالم')));
      stubWrite(_profile(name: 'دينا', realName: 'سارة السالم'));
      final cubit = build();
      await cubit.load();

      await cubit.save(displayName: 'دينا', realName: 'سارة السالم');

      final sent = capturedWrite();
      expect(sent.displayName, 'دينا');
      expect(sent.realName, isNull);
      await cubit.close();
    });

    test('realName only — the write still happens', () async {
      // The old early-return compared the display name alone and swallowed
      // this case entirely.
      when(() => getMyProfile()).thenAnswer((_) async => Right(_profile()));
      stubWrite(_profile(realName: 'سارة السالم'));
      final cubit = build();
      await cubit.load();

      await cubit.save(displayName: 'سارة', realName: 'سارة السالم');

      final sent = capturedWrite();
      expect(sent.displayName, 'سارة');
      expect(sent.realName, 'سارة السالم');
      await cubit.close();
    });

    test('clearing a set realName sends an empty string', () async {
      when(
        () => getMyProfile(),
      ).thenAnswer((_) async => Right(_profile(realName: 'سارة السالم')));
      stubWrite(_profile());
      final cubit = build();
      await cubit.load();

      await cubit.save(displayName: 'سارة', realName: '');

      expect(capturedWrite().realName, '');
      await cubit.close();
    });

    test('an already-absent realName left empty is omitted', () async {
      // Nothing to clear, so there is nothing to send — but the display name
      // did change, so the call itself must still go out.
      when(() => getMyProfile()).thenAnswer((_) async => Right(_profile()));
      stubWrite(_profile(name: 'دينا'));
      final cubit = build();
      await cubit.load();

      await cubit.save(displayName: 'دينا', realName: '   ');

      expect(capturedWrite().realName, isNull);
      await cubit.close();
    });

    test('both names are trimmed before comparison and sending', () async {
      when(() => getMyProfile()).thenAnswer((_) async => Right(_profile()));
      stubWrite(_profile(name: 'دينا', realName: 'سارة السالم'));
      final cubit = build();
      await cubit.load();

      await cubit.save(displayName: '  دينا  ', realName: '  سارة السالم  ');

      final sent = capturedWrite();
      expect(sent.displayName, 'دينا');
      expect(sent.realName, 'سارة السالم');
      await cubit.close();
    });
  });

  group('save — guards', () {
    test('an unchanged pair is not written', () async {
      when(
        () => getMyProfile(),
      ).thenAnswer((_) async => Right(_profile(realName: 'سارة السالم')));
      final cubit = build();
      await cubit.load();

      await cubit.save(displayName: '  سارة  ', realName: '  سارة السالم  ');

      verifyNoWrite();
      await cubit.close();
    });

    test('an empty displayName is not written, even with a new realName',
        () async {
      // displayName is required on every call, so there is no payload to send.
      when(() => getMyProfile()).thenAnswer((_) async => Right(_profile()));
      final cubit = build();
      await cubit.load();

      await cubit.save(displayName: '   ', realName: 'سارة السالم');

      verifyNoWrite();
      await cubit.close();
    });
  });

  group('save — outcomes', () {
    test('re-seeds from the returned profile and updates the gate', () async {
      when(() => getMyProfile()).thenAnswer(
        (_) async => Right(_profile(name: 'مستخدم', isDefaultName: true)),
      );
      stubWrite(_profile(name: 'سارة', realName: 'سارة السالم'));
      final cubit = build();
      await cubit.load();

      await cubit.save(displayName: 'سارة', realName: 'سارة السالم');

      expect(cubit.state.displayName, 'سارة');
      expect(cubit.state.realName, 'سارة السالم');
      expect(cubit.state.event, DisplayNameEvent.saved);
      expect(cubit.state.saving, isFalse);
      // No refetch — the gate is fed from the PUT response.
      verify(() => getMyProfile()).called(1);
      final resolved = gate.state as ProfileGateResolved;
      expect(resolved.name, 'سارة');
      expect(resolved.isDefaultName, isFalse);
      await cubit.close();
    });

    test('a rejection surfaces the server message verbatim', () async {
      when(() => getMyProfile()).thenAnswer((_) async => Right(_profile()));
      when(
        () => updateProfile(
          displayName: any(named: 'displayName'),
          realName: any(named: 'realName'),
        ),
      ).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'رسالة من الخادم')),
      );
      final cubit = build();
      await cubit.load();

      await cubit.save(displayName: 'اسم جديد');

      expect(cubit.state.event, DisplayNameEvent.saveFailed);
      expect(cubit.state.errorMessage, 'رسالة من الخادم');
      expect(cubit.state.saving, isFalse);
      // Keeps the previous name on screen — a failed write must not blank it.
      expect(cubit.state.displayName, 'سارة');
      await cubit.close();
    });

    test('no rejection triggers a re-read — the lock retry path is gone', () async {
      when(() => getMyProfile()).thenAnswer((_) async => Right(_profile()));
      when(
        () => updateProfile(
          displayName: any(named: 'displayName'),
          realName: any(named: 'realName'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          CodedServerFailure(message: 'خطأ', errorCode: 'SOMETHING_ELSE'),
        ),
      );
      final cubit = build();
      await cubit.load();

      await cubit.save(displayName: 'اسم جديد');

      verify(() => getMyProfile()).called(1);
      await cubit.close();
    });
  });
}
