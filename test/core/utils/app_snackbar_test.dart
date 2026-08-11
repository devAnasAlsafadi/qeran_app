import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/core/utils/widgets/qeran_snack_bar_widget.dart';
import 'package:qeran/core/widgets/bottom_chrome_inset.dart';

void main() {
  setUp(() {
    AppSnackBar.debugReset();
    BottomChromeInsets.debugReset();
  });
  tearDown(() {
    AppSnackBar.debugReset();
    BottomChromeInsets.debugReset();
  });

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: AppSnackBarHost(
          child: Builder(
            builder: (builderContext) {
              context = builderContext;
              return const Scaffold(body: SizedBox.expand());
            },
          ),
        ),
      ),
    );
    return context;
  }

  testWidgets('deduplicates repeated identical messages', (tester) async {
    final context = await pumpHost(tester);

    for (var index = 0; index < 10; index++) {
      await AppSnackBar.show(
        context,
        message: 'Profile is under review',
        type: SnackBarType.notice,
      );
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(QeranSnackBarWidget), findsOneWidget);
    expect(find.text('Profile is under review'), findsOneWidget);

    AppSnackBar.debugReset();
    await tester.pump();
  });

  testWidgets('stacks different messages without overlap', (tester) async {
    final context = await pumpHost(tester);

    await AppSnackBar.show(
      context,
      message: 'First message',
      type: SnackBarType.info,
    );
    await AppSnackBar.show(
      context,
      message: 'Second message',
      type: SnackBarType.error,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final snackBars = find.byType(QeranSnackBarWidget);
    expect(snackBars, findsNWidgets(2));
    expect(
      tester.getRect(snackBars.at(0)).bottom,
      lessThanOrEqualTo(tester.getRect(snackBars.at(1)).top),
    );

    AppSnackBar.debugReset();
    await tester.pump();
  });

  testWidgets('queues messages after the three visible slots', (tester) async {
    final context = await pumpHost(tester);

    for (var index = 1; index <= 4; index++) {
      await AppSnackBar.show(
        context,
        message: 'Message $index',
        type: SnackBarType.info,
      );
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(QeranSnackBarWidget), findsNWidgets(3));
    expect(find.text('Message 4'), findsNothing);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pump(const Duration(milliseconds: 180));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(QeranSnackBarWidget), findsNWidgets(3));
    expect(find.text('Message 4'), findsOneWidget);

    AppSnackBar.debugReset();
    await tester.pump();
  });

  testWidgets('error tone wears the soft danger surface, not a solid red', (
    tester,
  ) async {
    final context = await pumpHost(tester);

    await AppSnackBar.show(
      context,
      message: 'Something failed',
      type: SnackBarType.error,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final decoration =
        tester
                .widget<Container>(
                  find.descendant(
                    of: find.byType(QeranSnackBarWidget),
                    matching: find.byType(Container),
                  ),
                )
                .decoration
            as BoxDecoration;

    // danger-12 composited over paper — opaque (a translucent surface would
    // let the page bleed through) and NOT the solid danger banner.
    expect(decoration.color, isNotNull);
    expect(decoration.color!.a, 1.0);
    expect(decoration.color, isNot(QeranColors.danger));
    expect(
      decoration.color,
      Color.alphaBlend(QeranColors.danger12, QeranColors.paper),
    );

    // danger-40 hairline + danger ink on the icon.
    expect(
      (decoration.border as Border).top.color,
      QeranColors.danger40,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.error_outline_rounded)).color,
      QeranColors.danger,
    );

    AppSnackBar.debugReset();
    await tester.pump();
  });

  // QER-32. At the bottom the toast lands on the cream canvas, so a paper card
  // was white-on-near-white and dissolved into the page. Filled wine reads as a
  // floating layer on every background the app has.
  testWidgets('success tone is filled wine with a gold icon', (tester) async {
    final context = await pumpHost(tester);

    await AppSnackBar.show(
      context,
      message: 'Signed in',
      type: SnackBarType.success,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final decoration =
        tester
                .widget<Container>(
                  find.descendant(
                    of: find.byType(QeranSnackBarWidget),
                    matching: find.byType(Container),
                  ),
                )
                .decoration
            as BoxDecoration;

    expect(decoration.color, QeranColors.wine);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.check_circle_rounded)).color,
      QeranColors.gold,
    );

    AppSnackBar.debugReset();
    await tester.pump();
  });

  // The host is mounted once above the Navigator, so this single
  // assertion covers all 110 call sites across both roles.
  testWidgets('toast is anchored to the bottom, clear of the safe area', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 820);
    tester.view.devicePixelRatio = 1.0;
    // A real gesture-bar inset — with zero the toast could sit flush on the
    // home indicator and this test would still pass.
    tester.view.padding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.reset);

    final context = await pumpHost(tester);
    await AppSnackBar.show(
      context,
      message: 'Saved',
      type: SnackBarType.success,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final card = tester.getRect(find.byType(QeranSnackBarWidget));
    // Well below the middle — this is the assertion that fails if anyone
    // moves the host back to the top.
    expect(card.top, greaterThan(410));
    // Above the gesture inset (34) plus the host's own 20px minimum.
    expect(820 - card.bottom, greaterThanOrEqualTo(54.0));

    AppSnackBar.debugReset();
    await tester.pump();
  });

  // The host sits above the Navigator, so it cannot see which route is showing
  // and cannot read anything a screen provides. Chrome declares its own
  // footprint through the global registry instead; this is that contract.
  testWidgets('toast clears chrome that declares itself', (tester) async {
    tester.view.physicalSize = const Size(390, 820);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.reset);

    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: AppSnackBarHost(
          child: Builder(
            builder: (builderContext) {
              context = builderContext;
              return Scaffold(
                body: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      // Stands in for the bottom nav / the deck's action
                      // cluster: 200px of chrome pinned to the bottom edge.
                      child: const BottomChromeInset(
                        child: SizedBox(height: 200),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    // The footprint is measured and registered post-frame, by design — the
    // render box has no geometry until layout has run.
    await tester.pump();

    await AppSnackBar.show(
      context,
      message: 'Saved',
      type: SnackBarType.success,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(BottomChromeInsets.clearance.value, 200);
    final card = tester.getRect(find.byType(QeranSnackBarWidget));
    // Clear of the chrome's top edge (820 - 200), not merely of the safe area.
    expect(card.bottom, lessThanOrEqualTo(620.0));

    AppSnackBar.debugReset();
    BottomChromeInsets.debugReset();
    await tester.pump();
  });

  // A screen with no chrome must not pay for the mechanism: auth declares
  // nothing, so the toast keeps its plain safe-area clearance.
  testWidgets('no declared chrome leaves the toast at the safe area', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 820);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.reset);

    final context = await pumpHost(tester);
    await tester.pump();
    await AppSnackBar.show(
      context,
      message: 'Saved',
      type: SnackBarType.success,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(BottomChromeInsets.clearance.value, 0);
    final card = tester.getRect(find.byType(QeranSnackBarWidget));
    expect(820 - card.bottom, 54.0);

    AppSnackBar.debugReset();
    await tester.pump();
  });
}
