import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/purchase/package_purchase_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/purchase/package_purchase_state.dart';
import 'package:qeran/features/subscriptions/presentation/widgets/restore_purchases_tile.dart';

import '../../../../core/shipped_strings_rig.dart';

class _MockPurchase extends Mock implements PackagePurchaseCubit {}

/// «استعادة المشتريات»'s chevron points forward in both languages: one
/// self-mirroring icon. It was swapped by hand on top of the mirroring, so
/// English pointed back (cleanup audit `19`, run 11).
void main() {
  setUpAll(initShippedStrings);

  setUp(() {
    final purchase = _MockPurchase();
    when(() => purchase.state).thenReturn(const PackagePurchaseIdle());
    when(() => purchase.stream).thenAnswer((_) => const Stream.empty());
    when(() => purchase.close()).thenAnswer((_) async {});
    sl.registerFactory<PackagePurchaseCubit>(() => purchase);
  });

  tearDown(sl.reset);

  for (final (lang, direction) in [
    ('en', TextDirection.ltr),
    ('ar', TextDirection.rtl),
  ]) {
    testWidgets('$lang: the self-mirroring chevron, forward', (tester) async {
      await pumpShippedStrings(
        tester,
        Locale(lang),
        child: const RestorePurchasesTile(),
      );

      final chevron = find.byIcon(Icons.chevron_right_rounded);
      expect(chevron, findsOneWidget);
      expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);
      expect(Icons.chevron_right_rounded.matchTextDirection, isTrue);
      expect(Directionality.of(tester.element(chevron)), direction);
    });
  }
}
