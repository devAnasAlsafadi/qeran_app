import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/core/utils/widgets/qeran_snack_bar_widget.dart';

void main() {
  setUp(AppSnackBar.debugReset);
  tearDown(AppSnackBar.debugReset);

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
}
