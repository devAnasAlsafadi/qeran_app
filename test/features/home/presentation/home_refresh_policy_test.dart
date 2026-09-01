import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/features/home/presentation/home_refresh_policy.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';

class _MockProfileGate extends Mock implements ProfileGateCubit {}

class _MockBadges extends Mock implements BadgesCubit {}

class _MockSubscription extends Mock implements CurrentSubscriptionCubit {}

void main() {
  late _MockProfileGate profileGate;
  late _MockBadges badges;
  late _MockSubscription subscription;
  late HomeRefreshPolicy policy;

  setUp(() {
    profileGate = _MockProfileGate();
    badges = _MockBadges();
    subscription = _MockSubscription();
    policy = HomeRefreshPolicy(
      profileGate: profileGate,
      badges: badges,
      subscription: subscription,
    );
    when(() => profileGate.refresh()).thenAnswer((_) async {});
    when(() => badges.refresh()).thenAnswer((_) async {});
    when(() => badges.clear()).thenReturn(null);
    // Default to the common case: an approved member, gate open.
    when(() => profileGate.isGated).thenReturn(false);
    when(
      () => subscription.refresh(force: any(named: 'force')),
    ).thenAnswer((_) async {});
  });

  group('onShellMount', () {
    test('refreshes the gate so a previous account\'s status cannot carry over',
        () async {
      await policy.onShellMount();

      verify(() => profileGate.refresh()).called(1);
    });

    test('clears the badges BEFORE refetching them', () async {
      await policy.onShellMount();

      // Reversed, the server's counts would land first and then be wiped to
      // zero — the shell would open with every dot missing.
      verifyInOrder([() => badges.clear(), () => badges.refresh()]);
    });

    test('does not refetch the subscription', () async {
      await policy.onShellMount();

      verifyNever(() => subscription.refresh(force: any(named: 'force')));
    });
  });

  group('onResume', () {
    test('refreshes the badges', () async {
      await policy.onResume();

      verify(() => badges.refresh()).called(1);
    });

    test('forces the subscription refetch past its cache', () async {
      await policy.onResume();

      verify(() => subscription.refresh(force: true)).called(1);
    });

    test('does not clear the badges', () async {
      await policy.onResume();

      // Only a new session starts from zero. Blanking on every resume would
      // drop dots the user has not acted on.
      verifyNever(() => badges.clear());
    });

    test('refreshes the gate, so an approval no longer needs a restart',
        () async {
      await policy.onResume();

      verify(() => profileGate.refresh()).called(1);
    });

    test('refreshes the gate even when the gate is already open', () async {
      when(() => profileGate.isGated).thenReturn(false);

      await policy.onResume();

      // Unconditional on purpose. Refreshing only while gated would let an
      // approval open the gate and never let a later hide or rejection close
      // it — the bug we are fixing, mirrored.
      verify(() => profileGate.refresh()).called(1);
    });
  });

  group('onForegroundPush', () {
    test('refreshes the badges', () async {
      await policy.onForegroundPush();

      verify(() => badges.refresh()).called(1);
    });

    test('does not refetch the subscription', () async {
      await policy.onForegroundPush();

      verifyNever(() => subscription.refresh(force: any(named: 'force')));
    });

    test('refreshes the gate while the gate is closed', () async {
      when(() => profileGate.isGated).thenReturn(true);

      await policy.onForegroundPush();

      // Covers the member who never backgrounds the app, so `onResume` never
      // fires: the approval push itself is what re-reads the status.
      verify(() => profileGate.refresh()).called(1);
    });

    test('does not refresh the gate when it is already open', () async {
      when(() => profileGate.isGated).thenReturn(false);

      await policy.onForegroundPush();

      // The mirror of the resume defence. An approved member receives the
      // overwhelming majority of pushes and must pay nothing for this hook.
      verifyNever(() => profileGate.refresh());
    });
  });
}
