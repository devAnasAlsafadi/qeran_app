import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/onboarding/presentation/widgets/custom_dot_indicator.dart';

Widget _host({required ValueChanged<int> onTap}) => MaterialApp(
  home: Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      body: Center(
        child: CustomDotIndicator(count: 3, activeIndex: 0, onTap: onTap),
      ),
    ),
  ),
);

void main() {
  testWidgets('each dot is tappable across 48dp of height', (tester) async {
    await tester.pumpWidget(_host(onTap: (_) {}));

    final targets = find.byType(GestureDetector);
    expect(targets, findsNWidgets(3));
    for (var i = 0; i < 3; i++) {
      expect(
        tester.getSize(targets.at(i)).height,
        greaterThanOrEqualTo(48),
        reason: 'dot $i must meet the 48dp minimum on the vertical axis',
      );
    }
  });

  testWidgets('the painted dot stays 7px — only the target grew', (
    tester,
  ) async {
    await tester.pumpWidget(_host(onTap: (_) {}));

    final painted = find.byType(AnimatedContainer);
    expect(painted, findsNWidgets(3));
    for (var i = 0; i < 3; i++) {
      expect(tester.getSize(painted.at(i)).height, 7);
    }
    // Active dot is the wide pill, the other two the small dots.
    expect(tester.getSize(painted.at(0)).width, 22);
    expect(tester.getSize(painted.at(1)).width, 7);
  });

  testWidgets('tapping a dot reports its index', (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(_host(onTap: tapped.add));

    await tester.tap(find.byType(GestureDetector).at(2));
    expect(tapped, [2]);
  });
}
