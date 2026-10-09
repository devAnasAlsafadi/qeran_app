import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_state.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/plans/subscription_plans_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/plans/subscription_plans_state.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/purchase/package_purchase_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/purchase/package_purchase_state.dart';
import 'package:qeran/features/subscriptions/presentation/screens/packages_screen.dart';
import 'package:qeran/features/subscriptions/presentation/widgets/paywall_hero_widget.dart';
import 'package:qeran/features/subscriptions/presentation/widgets/plan_selection_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../profile/presentation/fake_profile_gate.dart';
import '../widgets/subscription_widget_rig.dart';

class _MockPlans extends Mock implements SubscriptionPlansCubit {}

class _MockPurchase extends Mock implements PackagePurchaseCubit {}

class _MockCurrent extends Mock implements CurrentSubscriptionCubit {}

/// C5: while a purchase is activating, the plans open with the same notice
/// «اشتراكي» shows, so nobody buys again thinking the first one failed. The
/// plans stay below it.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await loadShippedFonts();
  });

  setUp(() {
    final plans = _MockPlans();
    when(() => plans.state).thenReturn(
      SubscriptionPlansLoaded(
        plans: [planWith(tier: 1)],
        selectionByPlan: const {},
        storeResolved: true,
      ),
    );
    when(() => plans.stream).thenAnswer((_) => const Stream.empty());
    when(() => plans.load()).thenAnswer((_) async {});
    when(() => plans.close()).thenAnswer((_) async {});
    final purchase = _MockPurchase();
    when(() => purchase.state).thenReturn(const PackagePurchaseIdle());
    when(() => purchase.stream).thenAnswer((_) => const Stream.empty());
    when(() => purchase.close()).thenAnswer((_) async {});
    sl.registerFactory<SubscriptionPlansCubit>(() => plans);
    sl.registerFactory<PackagePurchaseCubit>(() => purchase);
  });

  tearDown(sl.reset);

  Future<void> open(WidgetTester tester, CurrentSubscriptionState state) async {
    final current = _MockCurrent();
    when(() => current.state).thenReturn(state);
    when(() => current.stream).thenAnswer((_) => const Stream.empty());
    await pumpSubscriptionWidget(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<CurrentSubscriptionCubit>.value(value: current),
          BlocProvider<ProfileGateCubit>.value(value: FakeGate()),
        ],
        child: const PackagesScreen(),
      ),
      page: true,
    );
  }

  final title = find.text(shippedSubscriptionsEn('activating_title'));
  final overdueLine = find.text(shippedSubscriptionsEn('activating_overdue'));

  testWidgets('activating: the notice first, the plans below it', (
    tester,
  ) async {
    await open(
      tester,
      CurrentSubscriptionActivating(since: DateTime.now(), overdue: false),
    );

    expect(title, findsOneWidget);
    expect(overdueLine, findsNothing);
    expect(find.byType(PlanSelectionWidget), findsOneWidget);
    expect(
      tester.getTopLeft(title).dy,
      lessThan(tester.getTopLeft(find.byType(PaywallHeroWidget)).dy),
    );
  });

  testWidgets('after ten minutes, the Help & support line', (tester) async {
    await open(
      tester,
      CurrentSubscriptionActivating(since: DateTime.now(), overdue: true),
    );

    expect(overdueLine, findsOneWidget);
  });

  testWidgets('no purchase waiting: no notice', (tester) async {
    await open(tester, const CurrentSubscriptionNone());

    expect(title, findsNothing);
    expect(find.byType(PlanSelectionWidget), findsOneWidget);
  });
}
