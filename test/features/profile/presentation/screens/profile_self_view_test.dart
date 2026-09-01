import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/profile/domain/entities/my_profile.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';
import 'package:qeran/features/profile/domain/usecases/get_my_profile_usecase.dart';
import 'package:qeran/features/profile/presentation/blocs/my_profile/my_profile_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/my_profile/my_profile_state.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_state.dart';
import 'package:qeran/features/profile/presentation/screens/profile_self_view.dart';
import 'package:qeran/features/profile/presentation/widgets/profile_status_chip.dart';

class _FakeGetMyProfile extends Fake implements GetMyProfileUseCase {}

/// Serves one fixed profile without touching the network.
class _FakeMyProfileCubit extends MyProfileCubit {
  _FakeMyProfileCubit(this._profile) : super(getMyProfile: _FakeGetMyProfile());

  final MyProfile _profile;

  @override
  Future<void> load() async => emit(MyProfileLoaded(_profile));
}

/// Parks the gate in one fixed state; nothing here ever fetches.
class _FakeGate extends ProfileGateCubit {
  _FakeGate(ProfileGateState initial)
    : super(getMyProfile: _FakeGetMyProfile()) {
    emit(initial);
  }

  @override
  Future<void> refresh() async {}
}

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

MyProfile _profile(ProfileStatus status) => MyProfile(
  id: 'me',
  name: 'Me',
  email: 'me@example.com',
  gender: '',
  birthDate: null,
  age: 0,
  profileStatus: status,
  hasAnsweredQuestions: true,
  profileImage: null,
  images: const [],
  placements: const [],
);

/// Pumps the self-view with the two statuses supplied INDEPENDENTLY, so a test
/// can make the gate and the profile payload disagree.
Future<void> _pump(
  WidgetTester tester, {
  required ProfileGateState gate,
  required ProfileStatus payloadStatus,
}) async {
  await sl.reset();
  sl.registerFactory<MyProfileCubit>(
    () => _FakeMyProfileCubit(_profile(payloadStatus)),
  );

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar')],
      startLocale: const Locale('ar'),
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: Scaffold(
            body: BlocProvider<ProfileGateCubit>.value(
              value: _FakeGate(gate),
              child: const ProfileSelfView(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  tearDown(() async => sl.reset());

  testWidgets('the chip reads the GATE, not the profile payload', (
    tester,
  ) async {
    // The two caches disagree: the gate has been refreshed since approval,
    // the profile payload behind the hero has not. The gate must win — this
    // is the whole point of collapsing the second copy.
    await _pump(
      tester,
      gate: const ProfileGateResolved(ProfileStatus.visible),
      payloadStatus: ProfileStatus.pendingReview,
    );

    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    expect(find.byIcon(Icons.hourglass_top_rounded), findsNothing);
  });

  testWidgets('a pending gate draws the pending chip', (tester) async {
    await _pump(
      tester,
      gate: const ProfileGateResolved(ProfileStatus.pendingReview),
      payloadStatus: ProfileStatus.visible,
    );

    expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
  });

  testWidgets('an unresolved gate draws no chip at all', (tester) async {
    await _pump(
      tester,
      gate: const ProfileGateLoading(),
      payloadStatus: ProfileStatus.pendingReview,
    );

    // Loading and fail-open both land here. Identical to what an unrecognised
    // status has always drawn: nothing, and no padding either.
    expect(find.byType(ProfileStatusChip), findsNothing);
  });

  testWidgets('a fail-open gate draws no chip', (tester) async {
    await _pump(
      tester,
      gate: const ProfileGateUnavailable(),
      payloadStatus: ProfileStatus.visible,
    );

    expect(find.byType(ProfileStatusChip), findsNothing);
  });

  testWidgets('an unrecognised status draws no chip', (tester) async {
    await _pump(
      tester,
      gate: const ProfileGateResolved(ProfileStatus.unknown),
      payloadStatus: ProfileStatus.visible,
    );

    expect(find.byType(ProfileStatusChip), findsNothing);
  });
}
