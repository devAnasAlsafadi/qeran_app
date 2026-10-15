import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/subscriptions/domain/entities/current_subscription.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_plan.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_state.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/plans/subscription_plans_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/plans/subscription_plans_state.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/purchase/package_purchase_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/purchase/package_purchase_state.dart';
import 'package:qeran/features/subscriptions/presentation/screens/packages_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../profile/presentation/fake_profile_gate.dart';
import '../../top_plan_fixtures.dart';
import '../widgets/plans_store_rig.dart';
import '../widgets/subscription_widget_rig.dart';

class _MockPlans extends Mock implements SubscriptionPlansCubit {}

class _MockPurchase extends Mock implements PackagePurchaseCubit {}

class _MockCurrent extends Mock implements CurrentSubscriptionCubit {}

String _en(String key) => shippedSubscriptionsEn(key);

/// Run 11 (Anas): the plans screen for every member. No celebration: the top
/// plan lists itself for the period they don't hold; no plan below theirs;
/// «ترقية متاحة» only above it; their plan and period «باقتك الحالية», the
/// button off when it is chosen. «ترقية الاشتراك» on «اشتراكي» opens this
/// same screen.
void main() {
  late _MockPurchase purchase;

  setUpAll(() async {
    registerFallbackValue(vipMonth);
    registerFallbackValue(planOf());
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await loadShippedFonts();
  });

  tearDown(sl.reset);

  Future<void> open(WidgetTester tester, CurrentSubscription? owned) async {
    // The cubit's own defaults (VIP's popular 3 months), then their picks.
    final picked = <int, int>{vip.id: vipQuarter.id, basic.id: basicMonth.id};
    final plans = _MockPlans();
    when(() => plans.state).thenReturn(
      SubscriptionPlansLoaded(
        plans: [free, basic, vip],
        selectionByPlan: picked,
        storeProducts: {
          for (final p in [vipMonth, vipQuarter, basicMonth])
            p.googleProductId!: productOf(p.googleProductId!, 'SAR 50'),
        },
        storeResolved: true,
      ),
    );
    when(() => plans.stream).thenAnswer((_) => const Stream.empty());
    when(() => plans.load()).thenAnswer((_) async {});
    when(() => plans.close()).thenAnswer((_) async {});
    when(() => plans.pricingFor(any())).thenAnswer((call) {
      final plan = call.positionalArguments.single as SubscriptionPlan;
      return plan.pricings.firstWhere((p) => p.id == picked[plan.id]);
    });
    when(
      () => plans.selectPricing(
        planId: any(named: 'planId'),
        pricingId: any(named: 'pricingId'),
      ),
    ).thenAnswer((call) {
      picked[call.namedArguments[#planId] as int] =
          call.namedArguments[#pricingId] as int;
    });
    purchase = _MockPurchase();
    when(() => purchase.state).thenReturn(const PackagePurchaseIdle());
    when(() => purchase.stream).thenAnswer((_) => const Stream.empty());
    when(() => purchase.close()).thenAnswer((_) async {});
    when(
      () => purchase.purchase(pricing: any(named: 'pricing')),
    ).thenAnswer((_) async {});
    final current = _MockCurrent();
    when(() => current.state).thenReturn(
      owned == null
          ? const CurrentSubscriptionNone()
          : CurrentSubscriptionLoaded(owned),
    );
    when(() => current.stream).thenAnswer((_) => const Stream.empty());
    when(() => current.subscription).thenReturn(owned);
    sl.registerFactory<SubscriptionPlansCubit>(() => plans);
    sl.registerFactory<PackagePurchaseCubit>(() => purchase);
    sl.registerSingleton<CurrentSubscriptionCubit>(current);
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

  final buy = find.widgetWithText(QeranButton, _en('subscribe_now'));
  final ownedButton = find.widgetWithText(QeranButton, _en('badge_your_plan'));
  final upgrade = find.text(_en('badge_upgrade_available'));
  final codeField = find.byType(QeranTextField);
  final basicCard = find.text('Basic');
  final vipCard = find.text('VIP');

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).first);
    await tester.pumpAndSettle();
  }

  QeranButton button(WidgetTester tester, Finder finder) =>
      tester.widget<QeranButton>(finder);

  testWidgets('VIP monthly: no celebration; VIP alone, its 3 months to buy', (
    tester,
  ) async {
    await open(tester, vipMonthly);

    expect(find.textContaining('highest plan'), findsNothing);
    expect(vipCard, findsWidgets);
    expect(basicCard, findsNothing);
    expect(find.text('${_en('badge_your_plan')} · Month'), findsOneWidget);
    expect(upgrade, findsNothing);
    expect(button(tester, buy).onPressed, isNotNull);

    await tester.tap(buy);
    await tester.pumpAndSettle();
    verify(() => purchase.purchase(pricing: vipQuarter)).called(1);
  });

  testWidgets('VIP monthly, their own month picked: «باقتك الحالية», off', (
    tester,
  ) async {
    await open(tester, vipMonthly);

    await tapText(tester, 'Month');

    expect(buy, findsNothing);
    expect(button(tester, ownedButton).onPressed, isNull);
    expect(codeField, findsNothing);
  });

  testWidgets('VIP 3 months: the month preselected, to buy', (tester) async {
    await open(tester, vipQuarterly);

    expect(find.text('${_en('badge_your_plan')} · 3 months'), findsOneWidget);
    await tester.tap(buy);
    await tester.pumpAndSettle();
    verify(() => purchase.purchase(pricing: vipMonth)).called(1);
  });

  testWidgets('Basic: VIP preselected, the only upgrade; Basic theirs', (
    tester,
  ) async {
    await open(tester, basicMonthly);

    expect(basicCard, findsWidgets);
    expect(upgrade, findsOneWidget);
    expect(
      find.text('${_en('badge_your_plan')} · Basic month'),
      findsOneWidget,
    );
    expect(button(tester, buy).onPressed, isNotNull);

    await tapText(tester, 'Basic');
    expect(button(tester, ownedButton).onPressed, isNull);
  });

  testWidgets('Free: both paid plans, each an upgrade, the free card here', (
    tester,
  ) async {
    await open(tester, freeTrial);

    expect(basicCard, findsWidgets);
    expect(vipCard, findsWidgets);
    expect(upgrade, findsNWidgets(2));
    expect(find.text(_en('badge_you_are_here')), findsOneWidget);
  });

  testWidgets('a manual grant: the screen of the plan it grants', (
    tester,
  ) async {
    await open(tester, manualGrant);

    expect(basicCard, findsNothing);
    expect(find.text('${_en('badge_your_plan')} · Month'), findsOneWidget);
    await tester.tap(buy);
    await tester.pumpAndSettle();
    verify(() => purchase.purchase(pricing: vipQuarter)).called(1);
  });

  testWidgets('none: both paid plans, no badge of theirs, no upgrade', (
    tester,
  ) async {
    await open(tester, null);

    expect(basicCard, findsWidgets);
    expect(vipCard, findsWidgets);
    expect(upgrade, findsNothing);
    expect(find.textContaining(_en('badge_your_plan')), findsNothing);
    expect(button(tester, buy).onPressed, isNotNull);
  });
}
