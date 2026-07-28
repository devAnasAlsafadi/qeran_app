import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_skeleton.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_card_skeleton.dart';

/// D3 — the shimmer has to promise the layout the loaded state delivers.
///
/// It used to draw a floating rounded card inset 18dp on each side with a
/// shadow — the pre-merge look. The merged screen is full-bleed, so the
/// shimmer snapped into a different shape the moment the deck arrived.

void main() {
  testWidgets('the shimmer fills the width — no floating-card inset', (
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
            child: DiscoveryCardSkeleton(),
          ),
        ),
      ),
    );

    final rect = tester.getRect(find.byKey(DiscoveryCardSkeleton.cardKey));
    expect(rect.left, 0);
    expect(rect.right, 400);
    expect(rect.top, 0);
    expect(rect.bottom, 800);
  });

  testWidgets('the photo block matches the loaded photo fraction', (
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
            child: DiscoveryCardSkeleton(),
          ),
        ),
      ),
    );

    // The first skeleton box is the photo block. Shared constant, so the
    // shimmer and the loaded card cannot drift apart.
    final photo = tester.getRect(find.byType(QeranSkeleton).first);
    expect(photo.height, 800 * kDiscoveryPhotoFraction);
    expect(photo.left, 0);
    expect(photo.right, 400);
  });

  testWidgets('still renders the shimmer hints', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DiscoveryCardSkeleton()),
      ),
    );

    // Photo block + heading + two body lines + three chips.
    expect(find.byType(QeranSkeleton), findsNWidgets(7));
  });

  testWidgets('keeps pull-to-refresh scrollability while loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 700, child: DiscoveryCardSkeleton()),
        ),
      ),
    );

    final scrollView = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(scrollView.physics, isA<AlwaysScrollableScrollPhysics>());
  });

  testWidgets('wraps detail hints when the viewport becomes short', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 350));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DiscoveryCardSkeleton())),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Wrap), findsOneWidget);
  });
}
