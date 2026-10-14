import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_state.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/plans/subscription_plans_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/plans/subscription_plans_state.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/purchase/package_purchase_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/purchase/package_purchase_state.dart';
import 'package:qeran/features/subscriptions/presentation/screens/packages_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/shipped_fonts_rig.dart' as fonts;
import '../../../core/shipped_strings_rig.dart';
import '../../profile/presentation/fake_profile_gate.dart';
import 'widgets/plans_store_rig.dart';
import 'widgets/subscription_widget_rig.dart';

class _MockPlans extends Mock implements SubscriptionPlansCubit {}

class _MockPurchase extends Mock implements PackagePurchaseCubit {}

class _MockCurrent extends Mock implements CurrentSubscriptionCubit {}

/// Runs 10 and 11, the plans screen with no store product: once the store has
/// answered without the chosen period, no buy button and no discount-code
/// field; one line in body text says the plan can't be bought now. While the
/// store is still answering, both stay (the button off).
void main() {
  setUpAll(() async {
    registerFallbackValue(planOf());
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await fonts.loadShippedFonts();
    await initShippedStrings();
  });

  tearDown(sl.reset);

  final quarter = productOf('qeran_vip_3month', 'SAR 99.99', period: 'P3M');
  final line = find.text(
    shippedSubscriptionsEn('purchase_package_not_found'),
    skipOffstage: false,
  );
  final buy = find.text(
    shippedSubscriptionsEn('subscribe_now'),
    skipOffstage: false,
  );
  final codeField = find.byType(QeranTextField, skipOffstage: false);

  Future<void> open(
    WidgetTester tester, {
    Map<String, dynamic> products = const {},
    bool resolved = true,
  }) async {
    final plans = _MockPlans();
    when(() => plans.state).thenReturn(
      SubscriptionPlansLoaded(
        plans: [planOf()],
        selectionByPlan: const {5: 10},
        storeProducts: {
          for (final e in products.entries) e.key: e.value,
        }.cast(),
        storeResolved: resolved,
      ),
    );
    when(() => plans.stream).thenAnswer((_) => const Stream.empty());
    when(() => plans.load()).thenAnswer((_) async {});
    when(() => plans.close()).thenAnswer((_) async {});
    when(() => plans.pricingFor(any())).thenReturn(vipQuarter);
    final purchase = _MockPurchase();
    when(() => purchase.state).thenReturn(const PackagePurchaseIdle());
    when(() => purchase.stream).thenAnswer((_) => const Stream.empty());
    when(() => purchase.close()).thenAnswer((_) async {});
    sl.registerFactory<SubscriptionPlansCubit>(() => plans);
    sl.registerFactory<PackagePurchaseCubit>(() => purchase);
    final current = _MockCurrent();
    when(() => current.state).thenReturn(const CurrentSubscriptionNone());
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
      settle: resolved,
    );
  }

  testWidgets('no store product: the line once, no buy button, no code field', (
    tester,
  ) async {
    await open(tester);

    expect(line, findsOneWidget);
    expect(buy, findsNothing);
    expect(codeField, findsNothing);
  });

  testWidgets('the line is body text, not small and muted', (tester) async {
    await open(tester);

    final style = tester.widget<Text>(line).style;
    expect(style?.fontSize, QeranTypography.body.fontSize);
    expect(style?.color, QeranTypography.body.color);
  });

  testWidgets('a store product: the buy button and the code field, no line', (
    tester,
  ) async {
    await open(tester, products: {quarter.identifier: quarter});

    expect(buy, findsOneWidget);
    expect(codeField, findsOneWidget);
    expect(line, findsNothing);
  });

  testWidgets(
    'the store still answering: the button, off; the field; no line',
    (tester) async {
      await open(tester, resolved: false);

      expect(buy, findsOneWidget);
      expect(codeField, findsOneWidget);
      expect(line, findsNothing);
    },
  );
}
