import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/presentation/video/community_stale_refresh.dart';

/// S19: a screen kept past its videos' 6 h links reads itself again when the
/// app comes back, or when it's shown again — and not before.
void main() {
  late DateTime now;
  late int reads;
  late ValueNotifier<bool> shown;

  setUp(() {
    now = DateTime.utc(2026, 10, 4, 9);
    reads = 0;
    shown = ValueNotifier(true);
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: ValueListenableBuilder<bool>(
        valueListenable: shown,
        builder: (_, enabled, child) =>
            TickerMode(enabled: enabled, child: child!),
        child: CommunityStaleRefresh(
          onStale: () => reads++,
          now: () => now,
          child: const SizedBox(),
        ),
      ),
    ),
  );

  void resume(WidgetTester tester) =>
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

  testWidgets('back within 6 h: nothing read', (tester) async {
    await pump(tester);

    now = now.add(const Duration(hours: 5, minutes: 59));
    resume(tester);

    expect(reads, 0);
  });

  testWidgets('back after 6 h: read again, once', (tester) async {
    await pump(tester);

    now = now.add(const Duration(hours: 7));
    resume(tester);
    resume(tester);

    expect(reads, 1);
  });

  testWidgets('its tab shown again after 6 h: read again', (tester) async {
    await pump(tester);
    shown.value = false;
    await tester.pump();

    now = now.add(const Duration(hours: 7));
    shown.value = true;
    await tester.pump();

    expect(reads, 1);
  });
}
