import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_like_burst.dart';

Future<void> _pump(
  WidgetTester tester, {
  required VoidCallback onComplete,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            DiscoveryLikeBurst(
              origin: const Offset(40, 700),
              target: const Offset(200, 150),
              onComplete: onComplete,
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('DiscoveryLikeBurst calls onComplete after its animation', (
    tester,
  ) async {
    var completed = false;
    await _pump(tester, onComplete: () => completed = true);
    expect(completed, isFalse, reason: 'not yet — animation just started');

    // 480 ms total duration. Pump 380 ms — still running.
    await tester.pump(const Duration(milliseconds: 380));
    expect(completed, isFalse);

    // Settle the rest.
    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });

  testWidgets('DiscoveryLikeBurst wraps its visual in an IgnorePointer', (
    tester,
  ) async {
    await _pump(tester, onComplete: () {});
    // Scope to the burst — Scaffold / MaterialApp use IgnorePointer
    // internally, so an unscoped find returns multiple matches.
    expect(
      find.descendant(
        of: find.byType(DiscoveryLikeBurst),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('DiscoveryLikeBurst disposes its AnimationController cleanly', (
    tester,
  ) async {
    // pumpAndSettle would surface a "ticker still attached" failure
    // if dispose() didn't release the controller.
    var completed = false;
    await _pump(tester, onComplete: () => completed = true);
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    // Unmount and pump again — no leaks reported.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
