import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/onboarding/presentation/widgets/frames/blur_reveal_portrait.dart';

void main() {
  testWidgets('blurs only behind the seam, over a sharp base', (tester) async {
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
    // Two stacked copies of the portrait, and EXACTLY one of them filtered:
    // the frosted layer behind the seam. A base blur would make this 2.
    expect(find.byType(Image), findsNWidgets(2));
    expect(find.byType(ImageFiltered), findsOneWidget);

    // The seam remains mounted while its controller advances.
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.byKey(const ValueKey<String>('onboarding-blur-reveal-seam')),
      findsOneWidget,
    );
  });
}
