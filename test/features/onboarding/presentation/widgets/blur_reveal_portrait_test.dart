import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/onboarding/presentation/widgets/frames/blur_reveal_portrait.dart';

void main() {
  testWidgets('keeps the moving seam and both blur states', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 360, height: 420, child: BlurRevealPortrait()),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('onboarding-blur-reveal-seam')),
      findsOneWidget,
    );
    expect(find.byType(ImageFiltered), findsNWidgets(2));

    // The seam remains mounted while its controller advances.
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.byKey(const ValueKey<String>('onboarding-blur-reveal-seam')),
      findsOneWidget,
    );
  });
}
