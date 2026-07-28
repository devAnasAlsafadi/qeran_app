import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_skeleton.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_card_skeleton.dart';

void main() {
  testWidgets('reserves the loaded card geometry and renders shimmer hints', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 800,
            child: DiscoveryCardSkeleton(bottomClearance: 160),
          ),
        ),
      ),
    );

    final card = find.byKey(DiscoveryCardSkeleton.cardKey);
    expect(card, findsOneWidget);
    expect(find.byType(QeranSkeleton), findsNWidgets(7));

    final rect = tester.getRect(card);
    expect(rect.left, 18);
    expect(rect.right, 382);
    expect(rect.top, 24);
    expect(rect.bottom, 640);
  });

  testWidgets('keeps pull-to-refresh scrollability while loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 700,
            child: DiscoveryCardSkeleton(bottomClearance: 140),
          ),
        ),
      ),
    );

    final scrollView = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(scrollView.physics, isA<AlwaysScrollableScrollPhysics>());
  });

  testWidgets('wraps detail hints when the loading card becomes narrow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 350));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DiscoveryCardSkeleton(bottomClearance: 50)),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Wrap), findsOneWidget);
  });
}
