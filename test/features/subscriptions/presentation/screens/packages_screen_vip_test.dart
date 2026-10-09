import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_state.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/plans/subscription_plans_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/plans/subscription_plans_state.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/purchase/package_purchase_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/purchase/package_purchase_state.dart';
import 'package:qeran/features/subscriptions/presentation/screens/packages_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/subscription_widget_rig.dart';

class _MockPlans extends Mock implements SubscriptionPlansCubit {}

class _MockPurchase extends Mock implements PackagePurchaseCubit {}

class _MockCurrent extends Mock implements CurrentSubscriptionCubit {}

/// A VIP member opening the plans sees the "everything is yours" card instead.
/// Its feature rows are fixed, so the serious-interests row would outlive the
/// server dropping that allowance on release day (Phase 4 A1).
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await loadShippedFonts();
  });

  setUp(() {
    final vip = planWith(seriousInterests: -1, tier: 2);
    final plans = _MockPlans();
    when(() => plans.state).thenReturn(
      SubscriptionPlansLoaded(plans: [vip], selectionByPlan: const {}),
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

  testWidgets('the VIP card lists no serious-interests row', (tester) async {
    final current = _MockCurrent();
    when(() => current.state).thenReturn(
      CurrentSubscriptionLoaded(
        subscriptionWith(allowed: -1, used: 0, remaining: -1, tier: 2),
      ),
    );
    when(() => current.stream).thenAnswer((_) => const Stream.empty());

    await pumpSubscriptionWidget(
      tester,
      BlocProvider<CurrentSubscriptionCubit>.value(
        value: current,
        child: const PackagesScreen(),
      ),
      page: true,
    );

    expect(
      find.text(shippedSubscriptionsEn('vip_celebrate_subtitle')),
      findsOneWidget,
    );
    expect(
      find.text(shippedSubscriptionsEn('feature_likes_label')),
      findsOneWidget,
    );
    expect(
      find.text(shippedSubscriptionsEn('feature_serious_interests_label')),
      findsNothing,
    );
  });
}
