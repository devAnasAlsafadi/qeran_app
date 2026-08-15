import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_nav.dart';
import 'package:qeran/core/widgets/scroll_hiding_nav_scaffold.dart';
import 'package:qeran/features/chat/presentation/widgets/nav_aware_composer.dart';

/// Guards the one number a pinned composer cannot get wrong: where its bottom
/// edge lands relative to the floating nav island.
///
/// This exists because the arithmetic looked right and shipped anyway. Inside a
/// Scaffold body that has a `bottomNavigationBar`, BOTH `padding.bottom` and
/// `viewPadding.bottom` read 0 — Scaffold removes the padding, and
/// `removePadding` subtracts it from `viewPadding` too. A composer that
/// reconstructs the island's position from MediaQuery therefore loses the whole
/// device inset and sinks into the nav by exactly that much, on devices with an
/// inset and nowhere else. Only measured geometry catches that.
void main() {
  const screenH = 800.0;
  const inset = 24.0;
  const composerHeight = 60.0;

  /// The topmost pixel the island actually PAINTS, from the screen's bottom
  /// edge. The gold disc crests above the bar, so this is not `barHeight`.
  const islandPaintTop =
      inset + QeranBottomNav.bMargin + QeranBottomNav.discCrest;

  final composerKey = GlobalKey();

  Widget harness() => MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, screenH),
            padding: EdgeInsets.only(bottom: inset),
            viewPadding: EdgeInsets.only(bottom: inset),
          ),
          child: ScrollHidingNavScaffold(
            currentIndex: 0,
            body: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: List.generate(
                      40,
                      (i) => SizedBox(height: 40, child: Text('$i')),
                    ),
                  ),
                ),
                NavAwareComposer(
                  // Mirrors ChatInputBar, whose own SafeArea must end up a
                  // no-op: the composer owns the inset, and paying it twice is
                  // what put a dead band under the text field.
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      key: composerKey,
                      height: composerHeight,
                      child: const ColoredBox(color: Color(0xFF00FF00)),
                    ),
                  ),
                ),
              ],
            ),
            navBuilder: (_) => QeranBottomNav(
              items: const [
                QeranNavItem(
                  outlineIcon: Icons.home_outlined,
                  filledIcon: Icons.home,
                  label: 'a',
                ),
                QeranNavItem(
                  outlineIcon: Icons.chat_outlined,
                  filledIcon: Icons.chat,
                  label: 'b',
                ),
              ],
              currentIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      );

  /// Distance from the screen's bottom edge to the composer's bottom edge.
  double composerBottomFromEdge(WidgetTester tester) =>
      screenH - tester.getRect(find.byKey(composerKey)).bottom;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('nav visible: composer clears the island paint, never overlaps',
      (tester) async {
    tester.view.physicalSize = const Size(400, screenH);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    final bottom = composerBottomFromEdge(tester);
    // Above the paint, by the intended gap — not merely "not overlapping".
    expect(bottom, greaterThan(islandPaintTop));
    expect(bottom - islandPaintTop, closeTo(6, 0.5));
    // The device inset must be inside that figure. Its loss was the whole bug,
    // and without this the numbers still look plausible on an inset-free phone.
    expect(bottom, greaterThan(inset));
  });

  testWidgets('nav hidden: composer settles onto the device inset',
      (tester) async {
    tester.view.physicalSize = const Size(400, screenH);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    // Scrolling down hides the island; the composer takes the bottom edge.
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();

    // Exactly the inset: no island to clear, and the SafeArea inside the
    // composer must NOT have added a second one on top.
    expect(composerBottomFromEdge(tester), closeTo(inset, 0.5));
  });

  testWidgets('outside a shell there is no island and no padding',
      (tester) async {
    tester.view.physicalSize = const Size(400, screenH);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // The matchmaker opens conversations as a pushed route — no nav to avoid.
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, screenH),
            padding: EdgeInsets.only(bottom: inset),
            viewPadding: EdgeInsets.only(bottom: inset),
          ),
          child: Column(
            children: [
              const Spacer(),
              NavAwareComposer(
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    key: composerKey,
                    height: composerHeight,
                    child: const ColoredBox(color: Color(0xFF00FF00)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(composerBottomFromEdge(tester), closeTo(inset, 0.5));
  });
}
