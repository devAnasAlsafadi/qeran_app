import 'package:dartz/dartz.dart' show Left;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/subscriptions/data/error_codes.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_plan.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_pricing.dart';
import 'package:qeran/features/subscriptions/domain/usecases/subscribe_usecase.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/plans/subscription_plans_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/plans/subscription_plans_state.dart';
import 'package:qeran/features/subscriptions/presentation/widgets/paywall_purchase_flow.dart';
import 'package:qeran/features/subscriptions/presentation/widgets/plan_selection_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'subscription_widget_rig.dart';

class _MockPlans extends Mock implements SubscriptionPlansCubit {}

class _MockGate extends Mock implements ProfileGateCubit {}

class _MockSubscribe extends Mock implements SubscribeUseCase {}

const _freePricing = SubscriptionPricing(
  id: 30,
  planId: 3,
  durationDays: 7,
  labelAr: null,
  labelEn: null,
  price: 0,
  originalPrice: null,
  discountPercent: 0,
  monthlyEquivalent: 0,
  sortOrder: 0,
  isActive: true,
  isPopular: false,
  storeProductId: null,
  appleProductId: null,
  googleProductId: null,
);

final _free = SubscriptionPlan(
  id: 3,
  nameAr: 'مجانية',
  nameEn: 'Free',
  descriptionAr: null,
  descriptionEn: null,
  icon: '',
  color: '#999999',
  sortOrder: 0,
  isActive: true,
  isPopular: false,
  isFree: true,
  tier: 0,
  features: planWith().features,
  pricings: const [_freePricing],
);

/// The free plan with its name and pricing label set as given.
SubscriptionPlan _withPricing({
  String nameAr = 'مجانية',
  String nameEn = 'Free',
  String? labelEn,
}) => SubscriptionPlan(
  id: 3,
  nameAr: nameAr,
  nameEn: nameEn,
  descriptionAr: null,
  descriptionEn: null,
  icon: '',
  color: '',
  sortOrder: 0,
  isActive: true,
  isPopular: false,
  isFree: true,
  tier: 0,
  features: planWith().features,
  pricings: [
    SubscriptionPricing(
      id: 30,
      planId: 3,
      durationDays: 30,
      labelAr: null,
      labelEn: labelEn,
      price: 0,
      originalPrice: null,
      discountPercent: 0,
      monthlyEquivalent: 0,
      sortOrder: 0,
      isActive: true,
      isPopular: false,
      storeProductId: null,
      appleProductId: null,
      googleProductId: null,
    ),
  ],
);

/// The plans screen's list, with or without the free plan in the payload.
Widget _selection({SubscriptionPlan? freePlan}) {
  final paid = planWith(tier: 1);
  return PlanSelectionWidget(
    plans: [paid],
    activeIndex: 0,
    activePlan: paid,
    selectedPricingFor: (_) => null,
    onPlanChanged: (_) {},
    onPricingSelected: (_) {},
    resolveStoreProduct: (_) => null,
    // Resolved, so the price says "unavailable" instead of a placeholder
    // that shimmers forever.
    storeResolved: true,
    freePlan: freePlan,
  );
}

/// The purchase flow's free activation, behind one button.
class _Activate extends StatefulWidget {
  const _Activate();

  @override
  State<_Activate> createState() => _ActivateState();
}

class _ActivateState extends State<_Activate>
    with PaywallPurchaseFlow<_Activate> {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => activateFree(context),
    child: const Text('activate'),
  );
}

/// H2 (§12.2): from release day the plans omit the free plan for anyone who
/// already used it, unless it's their active plan. The card shows only when
/// the payload has it; before the flip a used trial is still refused by code.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await loadShippedFonts();
  });

  tearDown(() async {
    AppSnackBar.debugReset();
    await sl.reset();
  });

  // Run 10: the free card's name is the plan's own (`nameEn` here).
  final freeTitle = _free.nameEn;

  testWidgets('no free plan in the payload: no free card', (tester) async {
    await pumpSubscriptionWidget(tester, _selection());

    expect(find.text(freeTitle), findsNothing);
    expect(
      find.text(shippedSubscriptionsEn('free_activate_cta')),
      findsNothing,
    );
  });

  testWidgets('the free plan in the payload: the card, with Activate', (
    tester,
  ) async {
    await pumpSubscriptionWidget(tester, _selection(freePlan: _free));

    expect(find.text(freeTitle), findsOneWidget);
    expect(
      find.text(shippedSubscriptionsEn('free_activate_cta')),
      findsOneWidget,
    );
  });

  // Run 10, plans item 6: the name and period are the API's; ours only stand
  // in when it sends none.
  testWidgets('its name and its period label from the API', (tester) async {
    await pumpSubscriptionWidget(
      tester,
      _selection(freePlan: _withPricing(labelEn: 'Free month')),
    );

    expect(find.text('Free'), findsOneWidget);
    expect(find.text('Free month'), findsOneWidget);
    expect(find.text(shippedSubscriptionsEn('free_plan_title')), findsNothing);
  });

  testWidgets('no period label: its days', (tester) async {
    await pumpSubscriptionWidget(tester, _selection(freePlan: _free));

    expect(find.text('7 days'), findsOneWidget);
  });

  testWidgets('no name sent: our title stands in', (tester) async {
    await pumpSubscriptionWidget(
      tester,
      _selection(
        freePlan: _withPricing(nameAr: '', nameEn: ''),
      ),
    );

    expect(
      find.text(shippedSubscriptionsEn('free_plan_title')),
      findsOneWidget,
    );
  });

  testWidgets('a used trial is still refused by its code, as a notice', (
    tester,
  ) async {
    final plans = _MockPlans();
    when(() => plans.state).thenReturn(
      SubscriptionPlansLoaded(plans: [_free], selectionByPlan: const {}),
    );
    when(() => plans.stream).thenAnswer((_) => const Stream.empty());
    final gate = _MockGate();
    when(() => gate.isGated).thenReturn(false);
    when(() => gate.stream).thenAnswer((_) => const Stream.empty());
    final subscribe = _MockSubscribe();
    when(() => subscribe(pricingId: _freePricing.id)).thenAnswer(
      (_) async => const Left(
        CodedServerFailure(
          message: 'errors.generic',
          errorCode: SubscriptionsErrorCodes.freePlanAlreadyUsed,
        ),
      ),
    );
    sl.registerFactory<SubscribeUseCase>(() => subscribe);

    await pumpSubscriptionWidget(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<SubscriptionPlansCubit>.value(value: plans),
          BlocProvider<ProfileGateCubit>.value(value: gate),
        ],
        child: const _Activate(),
      ),
      builder: (context, child) => AppSnackBarHost(child: child!),
    );
    await tester.tap(find.text('activate'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text(shippedSubscriptionsEn('free_already_used')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5)); // the toast's timers
  });
}
