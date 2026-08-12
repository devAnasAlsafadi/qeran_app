import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/profile/domain/entities/my_profile.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';
import 'package:qeran/features/profile/domain/usecases/get_my_profile_usecase.dart';
import 'package:qeran/features/profile/domain/usecases/update_display_name_usecase.dart';
import 'package:qeran/features/profile/presentation/blocs/display_name/display_name_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/display_name/display_name_state.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_state.dart';

class _MockGetMyProfile extends Mock implements GetMyProfileUseCase {}

class _MockUpdateDisplayName extends Mock implements UpdateDisplayNameUseCase {}

MyProfile _profile({
  String name = 'سارة',
  String? realName,
  bool isDefaultName = false,
  bool isLocked = false,
  DateTime? lockedUntil,
}) => MyProfile(
  id: 'u-1',
  name: name,
  realName: realName,
  isDefaultName: isDefaultName,
  isDisplayNameLocked: isLocked,
  displayNameLockedUntil: lockedUntil,
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
  late _MockUpdateDisplayName updateDisplayName;
  late ProfileGateCubit gate;

  final now = DateTime.utc(2026, 8, 12, 12);

  setUp(() {
    getMyProfile = _MockGetMyProfile();
    updateDisplayName = _MockUpdateDisplayName();
    // A real gate over a mock use case — the write-back path is what's under
    // test, so a stub would prove nothing.
    gate = ProfileGateCubit(getMyProfile: getMyProfile);
  });

  tearDown(() => gate.close());

  DisplayNameCubit build() => DisplayNameCubit(
    getMyProfile: getMyProfile,
    updateDisplayName: updateDisplayName,
    profileGate: gate,
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

  group('canEdit', () {
    test('the placeholder name is always editable, lock flag or not', () {
      // The backend exempts default-name users from the cooldown; honouring
      // the lock here would strand them on "مستخدم" forever.
      final state = DisplayNameState(
        profile: _profile(
          name: 'مستخدم',
          isDefaultName: true,
          isLocked: true,
          lockedUntil: now.add(const Duration(days: 5)),
        ),
      );
      expect(state.canEdit(now), isTrue);
    });

    test('a live cooldown blocks editing', () {
      final state = DisplayNameState(
        profile: _profile(
          isLocked: true,
          lockedUntil: now.add(const Duration(days: 5)),
        ),
      );
      expect(state.canEdit(now), isFalse);
    });

    test('a lock whose window has passed is treated as open', () {
      // Showing "you can edit in 0 days" to someone whose cooldown expired
      // would be a bug the server would not agree with.
      final state = DisplayNameState(
        profile: _profile(
          isLocked: true,
          lockedUntil: now.subtract(const Duration(hours: 1)),
        ),
      );
      expect(state.canEdit(now), isTrue);
    });

    test('a lock with no timestamp is still respected', () {
      final state = DisplayNameState(profile: _profile(isLocked: true));
      expect(state.canEdit(now), isFalse);
    });
  });

  group('save', () {
    test('re-seeds from the returned profile and updates the gate', () async {
      when(() => getMyProfile()).thenAnswer(
        (_) async => Right(_profile(name: 'مستخدم', isDefaultName: true)),
      );
      when(() => updateDisplayName('سارة')).thenAnswer(
        (_) async => Right(
          _profile(
            name: 'سارة',
            isLocked: true,
            lockedUntil: now.add(const Duration(days: 7)),
          ),
        ),
      );
      final cubit = build();
      await cubit.load();

      await cubit.save('  سارة  ');

      expect(cubit.state.displayName, 'سارة');
      expect(cubit.state.event, DisplayNameEvent.saved);
      expect(cubit.state.saving, isFalse);
      // No refetch — the gate is fed from the PUT response.
      verify(() => getMyProfile()).called(1);
      final resolved = gate.state as ProfileGateResolved;
      expect(resolved.name, 'سارة');
      expect(resolved.isDefaultName, isFalse);
      await cubit.close();
    });

    test('an unchanged name is not written', () async {
      // A no-op write would still burn the member's 7-day cooldown.
      when(() => getMyProfile()).thenAnswer((_) async => Right(_profile()));
      final cubit = build();
      await cubit.load();

      await cubit.save('  سارة  ');

      verifyNever(() => updateDisplayName(any()));
      await cubit.close();
    });

    test('an empty name is not written', () async {
      when(() => getMyProfile()).thenAnswer((_) async => Right(_profile()));
      final cubit = build();
      await cubit.load();

      await cubit.save('   ');

      verifyNever(() => updateDisplayName(any()));
      await cubit.close();
    });

    test('a rejection surfaces the server message verbatim', () async {
      when(() => getMyProfile()).thenAnswer((_) async => Right(_profile()));
      when(() => updateDisplayName(any())).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'رسالة من الخادم')),
      );
      final cubit = build();
      await cubit.load();

      await cubit.save('اسم جديد');

      expect(cubit.state.event, DisplayNameEvent.saveFailed);
      expect(cubit.state.errorMessage, 'رسالة من الخادم');
      expect(cubit.state.saving, isFalse);
      // Keeps the previous name on screen — a failed write must not blank it.
      expect(cubit.state.displayName, 'سارة');
      await cubit.close();
    });

    test('a cooldown rejection re-reads so the form locks itself', () async {
      final locked = _profile(
        isLocked: true,
        lockedUntil: now.add(const Duration(days: 4)),
      );
      // First read: our stale view, showing an editable form. Second read (the
      // quiet refresh after the rejection): the real, locked state.
      var reads = 0;
      when(() => getMyProfile()).thenAnswer((_) async {
        reads++;
        return Right(reads == 1 ? _profile() : locked);
      });
      when(() => updateDisplayName(any())).thenAnswer(
        (_) async => const Left(
          CodedServerFailure(
            message: 'الاسم مقفل',
            errorCode: kDisplayNameLockedCode,
          ),
        ),
      );
      final cubit = build();
      await cubit.load();
      expect(cubit.state.canEdit(now), isTrue);

      await cubit.save('اسم جديد');

      expect(reads, 2);
      expect(cubit.state.canEdit(now), isFalse);
      await cubit.close();
    });

    test('an ordinary rejection does not trigger a re-read', () async {
      when(() => getMyProfile()).thenAnswer((_) async => Right(_profile()));
      when(() => updateDisplayName(any())).thenAnswer(
        (_) async => const Left(
          CodedServerFailure(message: 'خطأ', errorCode: 'SOMETHING_ELSE'),
        ),
      );
      final cubit = build();
      await cubit.load();

      await cubit.save('اسم جديد');

      verify(() => getMyProfile()).called(1);
      await cubit.close();
    });
  });
}
