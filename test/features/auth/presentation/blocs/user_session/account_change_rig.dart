import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/services/google_sign_in_service.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/core/state/account_scope.dart';
import 'package:qeran/features/auth/domain/entities/user_entity.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/badges/domain/usecases/get_badges_usecase.dart';
import 'package:qeran/features/badges/domain/usecases/mark_tab_seen_usecase.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/features/likes/application/photo_view_session_clock.dart';
import 'package:qeran/features/notifications/presentation/blocs/notification_read_cubit.dart';
import 'package:qeran/features/profile/domain/entities/my_profile.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';
import 'package:qeran/features/profile/domain/usecases/get_my_profile_usecase.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/profile/presentation/default_name_banner_session.dart';
import 'package:qeran/features/subscriptions/domain/usecases/get_current_subscription_usecase.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';

class MockStorage extends Mock implements StorageService {}

class MockPrefs extends Mock implements SharedPrefService {}

class _MockGoogleSignIn extends Mock implements GoogleSignInService {}

class MockGetMyProfile extends Mock implements GetMyProfileUseCase {}

class MockGetBadges extends Mock implements GetBadgesUseCase {}

class _MockMarkSeen extends Mock implements MarkTabSeenUseCase {}

class MockGetCurrent extends Mock implements GetCurrentSubscriptionUseCase {}

const member = UserEntity(id: 'member-1', name: 'مستخدم', email: 'm@test.com');
const matchmaker = UserEntity(id: 'mm-1', name: 'أنس', email: 'mm@test.com');

/// A member who still owes Community both steps (D17, D7).
MyProfile memberProfile() => const MyProfile(
  id: 'member-1',
  name: 'مستخدم',
  email: null,
  gender: 'Female',
  birthDate: null,
  age: 28,
  profileStatus: ProfileStatus.visible,
  hasAnsweredQuestions: true,
  profileImage: null,
  images: [],
  placements: [],
  isDefaultName: true,
  communityGuidelinesAccepted: false,
);

/// The session and the app-scoped holders, joined to one [AccountScope]
/// exactly as the DI modules join them.
class AccountChangeRig {
  AccountChangeRig() {
    when(() => secure.remove(any())).thenAnswer((_) async {});
    when(() => secure.clear()).thenAnswer((_) async {});
    when(() => prefs.remove(any())).thenAnswer((_) async {});
    when(() => prefs.save<List<String>>(any(), any())).thenAnswer((_) async {});
    when(() => googleSignIn.signOut()).thenAnswer((_) async {});
    when(() => getProfile()).thenAnswer((_) async => Right(memberProfile()));
    when(() => getCurrent()).thenAnswer((_) async => const Right(null));
  }

  final scope = AccountScope();
  final secure = MockStorage();
  final prefs = MockPrefs();
  final googleSignIn = _MockGoogleSignIn();
  final getProfile = MockGetMyProfile();
  final getBadges = MockGetBadges();
  final getCurrent = MockGetCurrent();

  late final gate = scope.hold(
    ProfileGateCubit(getMyProfile: getProfile),
    (gate) => gate.reset(),
  );
  late final badges = scope.hold(
    BadgesCubit(getBadges: getBadges, markTabSeen: _MockMarkSeen()),
    (cubit) => cubit.clear(),
  );
  late final subscription = scope.hold(
    CurrentSubscriptionCubit(getCurrent: getCurrent),
    (cubit) => cubit.clear(),
  );
  late final reads = scope.hold(
    NotificationReadCubit(prefs: prefs),
    (cubit) => cubit.reset(),
  );
  late final banner = scope.hold(
    DefaultNameBannerSession(),
    (session) => session.reset(),
  );
  late final clock = scope.hold(
    PhotoViewSessionClock(),
    (clock) => clock.clear(),
  );
  late final session = UserSessionCubit(
    secureStorage: secure,
    sharedPrefs: prefs,
    googleSignIn: googleSignIn,
    accountScope: scope,
  );

  /// Builds every holder, as a member's shell would have by now.
  void buildHolders() {
    for (final holder in [gate, badges, subscription, reads, banner, clock]) {
      expect(holder, isNotNull);
    }
  }

  Future<void> close() async {
    await Future.wait([
      gate.close(),
      badges.close(),
      subscription.close(),
      reads.close(),
      session.close(),
    ]);
  }
}
