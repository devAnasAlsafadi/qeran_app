import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/widgets/app_lifecycle_privacy_shield.dart';
import 'package:qeran/core/widgets/privacy_shield_suppression.dart';

/// The shield sits above the Navigator, so it covers EVERY route. It exists to
/// keep a revealed photo, a chat, or profile data out of the app-switcher
/// snapshot. These tests pin that behaviour before it is touched, so any later
/// narrowing has to prove it left the protection intact.

/// The concealing fill the shield paints — matched by colour so the child's own
/// widgets can never be mistaken for it.
Finder _concealer() => find.byWidgetPredicate(
  (w) => w is ColoredBox && w.color == QeranColors.wine,
);

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: AppLifecyclePrivacyShield(
        // Deliberately paints nothing wine, so `_concealer` cannot match it.
        child: Text('protected content', textDirection: TextDirection.rtl),
      ),
    ),
  );
}

Future<void> _lifecycle(WidgetTester tester, AppLifecycleState state) async {
  tester.binding.handleAppLifecycleStateChanged(state);
  await tester.pump();
}

void main() {
  testWidgets('paints nothing over the app while it is in the foreground', (
    tester,
  ) async {
    await _pump(tester);

    expect(_concealer(), findsNothing);
    expect(find.text('protected content'), findsOneWidget);
  });

  testWidgets('conceals the moment the app stops being resumed', (
    tester,
  ) async {
    await _pump(tester);

    await _lifecycle(tester, AppLifecycleState.inactive);

    // `inactive` is the state an app-switcher gesture and a system alert both
    // produce — the snapshot is taken here, so the fill must already be up.
    expect(_concealer(), findsOneWidget);
  });

  testWidgets('stays concealed while backgrounded', (tester) async {
    await _pump(tester);

    await _lifecycle(tester, AppLifecycleState.inactive);
    await _lifecycle(tester, AppLifecycleState.paused);

    expect(_concealer(), findsOneWidget);
  });

  testWidgets('conceals when hidden', (tester) async {
    await _pump(tester);

    await _lifecycle(tester, AppLifecycleState.hidden);

    expect(_concealer(), findsOneWidget);
  });

  testWidgets('lifts the fill once the app is back in the foreground', (
    tester,
  ) async {
    await _pump(tester);
    await _lifecycle(tester, AppLifecycleState.inactive);
    expect(_concealer(), findsOneWidget);

    await _lifecycle(tester, AppLifecycleState.resumed);

    expect(_concealer(), findsNothing);
  });

  testWidgets('keeps the protected child mounted underneath', (tester) async {
    await _pump(tester);

    await _lifecycle(tester, AppLifecycleState.inactive);

    // The fill covers; it must not REPLACE. Swapping the child out would drop
    // its state and reset whatever screen the user was on.
    expect(find.text('protected content'), findsOneWidget);
  });

  testWidgets('the fill covers the whole surface', (tester) async {
    await _pump(tester);

    await _lifecycle(tester, AppLifecycleState.inactive);

    // A partial cover would leak the very content this exists to hide.
    expect(
      tester.getSize(_concealer()),
      tester.getSize(find.byType(AppLifecyclePrivacyShield)),
    );
  });

  testWidgets('survives repeated notifications of the same state', (
    tester,
  ) async {
    await _pump(tester);

    await _lifecycle(tester, AppLifecycleState.inactive);
    await _lifecycle(tester, AppLifecycleState.inactive);

    expect(_concealer(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('standing down for a screen that asks', () {
    Future<void> pumpWith(
      WidgetTester tester,
      ValueNotifier<bool> suppression,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppLifecyclePrivacyShield(
            suppression: suppression,
            child: const Text(
              'protected content',
              textDirection: TextDirection.rtl,
            ),
          ),
        ),
      );
    }

    testWidgets('a suppressing screen keeps the fill off', (tester) async {
      final suppression = ValueNotifier<bool>(true);
      addTearDown(suppression.dispose);
      await pumpWith(tester, suppression);

      await _lifecycle(tester, AppLifecycleState.inactive);

      // The splash case: the fill is the same wine as the canvas underneath, so
      // without this the screen looks correct and the animation is just gone.
      expect(_concealer(), findsNothing);
    });

    testWidgets('a suppression that reads false changes nothing', (
      tester,
    ) async {
      final suppression = ValueNotifier<bool>(false);
      addTearDown(suppression.dispose);
      await pumpWith(tester, suppression);

      await _lifecycle(tester, AppLifecycleState.inactive);

      expect(_concealer(), findsOneWidget);
    });

    testWidgets('the fill returns the moment the screen stops asking', (
      tester,
    ) async {
      final suppression = ValueNotifier<bool>(true);
      addTearDown(suppression.dispose);
      await pumpWith(tester, suppression);
      await _lifecycle(tester, AppLifecycleState.inactive);
      expect(_concealer(), findsNothing);

      // The splash disposing while the app is already backgrounded: whatever
      // route comes next must be covered, with no second lifecycle event to
      // prompt it.
      suppression.value = false;
      await tester.pump();

      expect(_concealer(), findsOneWidget);
    });

    testWidgets('suppressing while resumed leaves nothing to hide', (
      tester,
    ) async {
      final suppression = ValueNotifier<bool>(true);
      addTearDown(suppression.dispose);
      await pumpWith(tester, suppression);

      expect(_concealer(), findsNothing);
      expect(find.text('protected content'), findsOneWidget);
    });

    testWidgets('the protected child survives a suppressed background', (
      tester,
    ) async {
      final suppression = ValueNotifier<bool>(true);
      addTearDown(suppression.dispose);
      await pumpWith(tester, suppression);

      await _lifecycle(tester, AppLifecycleState.inactive);
      await _lifecycle(tester, AppLifecycleState.resumed);

      expect(find.text('protected content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the shared signal', () {
    testWidgets('starts down, so nothing is suppressed by default', (
      tester,
    ) async {
      // The default matters more than it looks: anything that forgets to set it
      // gets the shield, not a hole in it.
      expect(privacyShieldSuppressed.value, isFalse);
    });
  });
}
