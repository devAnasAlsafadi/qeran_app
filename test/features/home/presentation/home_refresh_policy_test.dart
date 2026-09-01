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

    test('does not refresh the gate — the staleness bug, pinned', () async {
      await policy.onResume();

      // Characterisation, NOT the desired behaviour: this is why an approval
      // needs a process kill to show up. Flipped in the next sub-step.
      verifyNever(() => profileGate.refresh());
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

    test('does not refresh the gate — the staleness bug, pinned', () async {
      await policy.onForegroundPush();

      // Characterisation, NOT the desired behaviour: the approval push lands
      // here and only the badges move. Flipped in a later sub-step.
      verifyNever(() => profileGate.refresh());
    });
  });
}
