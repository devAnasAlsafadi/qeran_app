import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/widgets/qeran_skeleton.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/purchase/package_purchase_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/purchase/package_purchase_state.dart';
import 'package:qeran/features/subscriptions/presentation/widgets/order_summary_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/shipped_fonts_rig.dart' as fonts;
import '../../../core/shipped_strings_rig.dart';
import 'widgets/plans_store_rig.dart';

class _MockPurchase extends Mock implements PackagePurchaseCubit {}

/// Run 10, plans item 2: the API's price fields are never shown. With no
/// store product the plan's content shows without a price, a «—» or a summary
/// price row. The screen's line and button: `plans_no_store_screen_test`.
void main() {
  setUpAll(() async {
    registerFallbackValue(planOf());
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await fonts.loadShippedFonts();
    await initShippedStrings();
  });

  final quarter = productOf('qeran_vip_3month', 'SAR 99.99', period: 'P3M');
  final month = productOf('qeran_vip_monthly', 'SAR 34.99', period: 'P1M');

  group('the plan list', () {
    testWidgets('no store product: the content, no price of any kind', (
      tester,
    ) async {
      await pumpPlans(tester, const Locale('ar'));

      expect(find.text('الباقة الذهبية'), findsOneWidget);
      expect(find.text('3 شهور'), findsOneWidget);
      expect(find.text('متابعة مكثفة من الخطّابة'), findsOneWidget);
      expect(find.text('—'), findsNothing);
      expect(find.textContaining('غير متوفرة'), findsNothing);
      for (final apiFigure in ['50', '120', r'$']) {
        expect(find.textContaining(apiFigure), findsNothing, reason: apiFigure);
      }
    });

    testWidgets('the store still answering: placeholders', (tester) async {
      await pumpPlans(tester, const Locale('ar'), storeResolved: false);

      expect(find.byType(QeranSkeleton), findsWidgets);
    });

    testWidgets('store products: their prices', (tester) async {
      await pumpPlans(
        tester,
        const Locale('ar'),
        products: {quarter.identifier: quarter, month.identifier: month},
      );

      expect(find.text('SAR 34.99'), findsOneWidget);
      expect(find.text('SAR 99.99'), findsOneWidget);
    });
  });

  group('the order summary', () {
    Future<void> pumpSummary(WidgetTester tester, {bool store = false}) {
      final purchase = _MockPurchase();
      when(() => purchase.state).thenReturn(const PackagePurchaseIdle());
      when(() => purchase.stream).thenAnswer((_) => const Stream.empty());
      return pumpShippedStrings(
        tester,
        const Locale('ar'),
        child: Scaffold(
          body: BlocProvider<PackagePurchaseCubit>.value(
            value: purchase,
            child: OrderSummaryWidget(
              planName: 'الباقة الذهبية',
              pricing: vipQuarter,
              storeProduct: store ? quarter : null,
              codeProductId: vipQuarter.googleProductId,
            ),
          ),
        ),
      );
    }

    testWidgets('no store product: no price row', (tester) async {
      await pumpSummary(tester);

      expect(find.text('الباقة الذهبية'), findsOneWidget);
      expect(find.text('السعر الأساسي'), findsNothing);
      expect(find.textContaining('120'), findsNothing);
      expect(find.textContaining(r'$'), findsNothing);
    });

    testWidgets('a store product: its price', (tester) async {
      await pumpSummary(tester, store: true);

      expect(find.text('السعر الأساسي'), findsOneWidget);
      expect(find.text('SAR 99.99'), findsOneWidget);
    });
  });
}
