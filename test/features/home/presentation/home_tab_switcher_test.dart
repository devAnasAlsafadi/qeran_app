import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/home/presentation/home_tab_switcher.dart';

HomeTabSwitcher _switcher(WidgetTester tester) {
  final tabs = HomeTabSwitcher(vsync: tester, initialTab: 0);
  addTearDown(tabs.dispose);
  return tabs;
}

void main() {
  // Cold start loads the landing tab only; the others fetch on first visit.
  testWidgets('starts on the initial tab, with only it mounted', (
    tester,
  ) async {
    final tabs = _switcher(tester);

    expect(tabs.currentTab, 0);
    expect(tabs.visited, [0]);
    expect(tabs.previousTab, isNull);
  });

  testWidgets('selecting the tab already showing changes nothing', (
    tester,
  ) async {
    final tabs = _switcher(tester);
    var notified = 0;
    tabs.addListener(() => notified++);

    await tabs.select(0);

    expect(notified, 0);
    expect(tabs.isAnimating, isFalse);
  });

  // The destination's first layout and fetch must not land on the first
  // frame of the visible slide.
  testWidgets('a first visit mounts the tab a frame before switching to it', (
    tester,
  ) async {
    final tabs = _switcher(tester);

    unawaited(tabs.select(2));

    expect(tabs.visited, containsAll([0, 2]));
    expect(tabs.currentTab, 0, reason: 'still the old tab for one frame');

    await tester.pump();

    expect(tabs.currentTab, 2);
    expect(tabs.previousTab, 0);

    await tester.pumpAndSettle();

    expect(tabs.previousTab, isNull, reason: 'the slide has finished');
  });

  testWidgets('a revisit switches at once, without remounting', (tester) async {
    final tabs = _switcher(tester);
    unawaited(tabs.select(1));
    await tester.pumpAndSettle();

    unawaited(tabs.select(0));

    expect(tabs.currentTab, 0);
    expect(tabs.previousTab, 1);
    expect(tabs.visited, [0, 1]);
    await tester.pumpAndSettle();
  });

  testWidgets('the direction follows the tab order', (tester) async {
    final tabs = _switcher(tester);

    unawaited(tabs.select(2));
    await tester.pumpAndSettle();
    expect(tabs.direction, 1);

    unawaited(tabs.select(1));
    await tester.pumpAndSettle();
    expect(tabs.direction, -1);
  });

  testWidgets('a switch requested mid-slide is ignored', (tester) async {
    final tabs = _switcher(tester);
    unawaited(tabs.select(1));
    await tester.pump();
    expect(tabs.isAnimating, isTrue);

    unawaited(tabs.select(2));
    await tester.pumpAndSettle();

    expect(tabs.currentTab, 1);
    expect(tabs.visited, isNot(contains(2)));
  });

  // The shell can be torn down while a first visit waits for its frame.
  testWidgets('a switch cut short by dispose does not touch the dead state', (
    tester,
  ) async {
    final tabs = HomeTabSwitcher(vsync: tester, initialTab: 0);
    var notified = 0;
    tabs.addListener(() => notified++);
    unawaited(tabs.select(2));
    final before = notified;

    tabs.dispose();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(notified, before);
  });
}
