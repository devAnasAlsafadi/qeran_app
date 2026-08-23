// easy_localization re-exports intl's TextDirection, which shadows the
// dart:ui one this test lays out against.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/features/onboarding/presentation/widgets/custom_dot_indicator.dart';
import 'package:qeran/features/onboarding/presentation/widgets/onboarding_circle_button.dart';
import 'package:qeran/features/onboarding/presentation/widgets/onboarding_nav_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

/// The next control resolves its label through EasyLocalization, so the row
/// cannot build without one in the tree.
Widget _host(
  OnboardingNavRow row, {
  TextDirection direction = TextDirection.rtl,
}) {
  return EasyLocalization(
    supportedLocales: const [Locale('ar')],
    path: 'assets/translations',
    assetLoader: const _StubAssetLoader(),
    child: Builder(
      builder: (context) => MaterialApp(
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        home: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: Center(child: SizedBox(width: 360, child: row)),
          ),
        ),
      ),
    ),
  );
}

/// The dots' centre relative to the row's centre. Both must coincide however
/// many controls are visible and however wide the next label runs.
double _dotsOffset(WidgetTester tester) {
  final dots = tester.getCenter(find.byType(CustomDotIndicator));
  final row = tester.getCenter(find.byType(OnboardingNavRow));
  return dots.dx - row.dx;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('first page: no back button, dots still centred', (tester) async {
    await tester.pumpWidget(
      _host(
        OnboardingNavRow(
          dotCount: 3,
          activeDot: 0,
          onDot: (_) {},
          onNext: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Next is a labelled button now; back is the only circle, and it is absent.
    expect(find.byType(OnboardingCircleButton), findsNothing);
    expect(find.byType(QeranButton), findsOneWidget);
    expect(_dotsOffset(tester), moreOrLessEquals(0, epsilon: 0.5));
  });

  testWidgets('middle page: both controls, dots centred', (tester) async {
    await tester.pumpWidget(
      _host(
        OnboardingNavRow(
          dotCount: 3,
          activeDot: 1,
          onDot: (_) {},
          onBack: () {},
          onNext: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingCircleButton), findsOneWidget);
    expect(find.byType(QeranButton), findsOneWidget);
    expect(_dotsOffset(tester), moreOrLessEquals(0, epsilon: 0.5));
  });

  testWidgets('last page: no next button, dots still centred', (tester) async {
    await tester.pumpWidget(
      _host(
        OnboardingNavRow(
          dotCount: 3,
          activeDot: 2,
          onDot: (_) {},
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(QeranButton), findsNothing);
    expect(find.byType(OnboardingCircleButton), findsOneWidget);
    expect(_dotsOffset(tester), moreOrLessEquals(0, epsilon: 0.5));
  });

  testWidgets('the next button keeps one width across locales', (tester) async {
    await tester.pumpWidget(
      _host(
        OnboardingNavRow(
          dotCount: 3,
          activeDot: 1,
          onDot: (_) {},
          onBack: () {},
          onNext: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Pinned, so a longer label in another language cannot move the control.
    expect(tester.getSize(find.byType(QeranButton)).width, 104);
  });

  testWidgets('back sits at the start edge in both directions', (tester) async {
    for (final direction in TextDirection.values) {
      await tester.pumpWidget(
        _host(
          OnboardingNavRow(
            dotCount: 3,
            activeDot: 1,
            onDot: (_) {},
            onBack: () {},
            onNext: () {},
          ),
          direction: direction,
        ),
      );
      await tester.pumpAndSettle();

      final back = tester.getCenter(find.byType(OnboardingCircleButton));
      final next = tester.getCenter(find.byType(QeranButton));
      // RTL start is the right edge; LTR start is the left.
      if (direction == TextDirection.rtl) {
        expect(back.dx, greaterThan(next.dx));
      } else {
        expect(back.dx, lessThan(next.dx));
      }
    }
  });

  testWidgets('taps reach the right callback', (tester) async {
    var back = 0;
    var next = 0;
    await tester.pumpWidget(
      _host(
        OnboardingNavRow(
          dotCount: 3,
          activeDot: 1,
          onDot: (_) {},
          onBack: () => back++,
          onNext: () => next++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(OnboardingCircleButton));
    await tester.tap(find.byType(QeranButton));
    expect(back, 1);
    expect(next, 1);
  });
}
