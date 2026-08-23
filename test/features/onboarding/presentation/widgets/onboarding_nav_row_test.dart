import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/onboarding/presentation/widgets/custom_dot_indicator.dart';
import 'package:qeran/features/onboarding/presentation/widgets/onboarding_circle_button.dart';
import 'package:qeran/features/onboarding/presentation/widgets/onboarding_nav_row.dart';

Widget _host(OnboardingNavRow row, {TextDirection direction = TextDirection.rtl}) {
  return MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: Center(child: SizedBox(width: 360, child: row)),
      ),
    ),
  );
}

/// The dots' centre relative to the row's centre. Both must coincide however
/// many controls are visible.
double _dotsOffset(WidgetTester tester) {
  final dots = tester.getCenter(find.byType(CustomDotIndicator));
  final row = tester.getCenter(find.byType(OnboardingNavRow));
  return dots.dx - row.dx;
}

void main() {
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

    // Only next is drawn — a hidden back must not leave a dead control behind.
    expect(find.byType(OnboardingCircleButton), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_rounded), findsNothing);
    expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);
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

    expect(find.byType(OnboardingCircleButton), findsNWidgets(2));
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

    expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsNothing);
    expect(find.byIcon(Icons.arrow_back_ios_rounded), findsOneWidget);
    expect(_dotsOffset(tester), moreOrLessEquals(0, epsilon: 0.5));
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

      final back = tester.getCenter(find.byIcon(Icons.arrow_back_ios_rounded));
      final next =
          tester.getCenter(find.byIcon(Icons.arrow_forward_ios_rounded));
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

    await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
    await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
    expect(back, 1);
    expect(next, 1);
  });
}
