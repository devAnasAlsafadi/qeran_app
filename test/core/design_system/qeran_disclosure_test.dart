import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_disclosure.dart';

Widget _host({bool initiallyExpanded = false}) => MaterialApp(
  home: Scaffold(
    body: QeranDisclosure(
      initiallyExpanded: initiallyExpanded,
      summary: const Text('summary'),
      child: const Text('body'),
    ),
  ),
);

void main() {
  testWidgets('closed, only the summary is on screen', (tester) async {
    await tester.pumpWidget(_host());

    expect(find.text('summary'), findsOneWidget);
    expect(find.text('body'), findsNothing);
  });

  testWidgets('tapping the summary row opens it', (tester) async {
    await tester.pumpWidget(_host());

    await tester.tap(find.text('summary'));
    await tester.pumpAndSettle();

    expect(find.text('body'), findsOneWidget);
  });

  testWidgets('tapping again closes it', (tester) async {
    await tester.pumpWidget(_host());

    await tester.tap(find.text('summary'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('summary'));
    await tester.pumpAndSettle();

    expect(find.text('body'), findsNothing);
  });

  testWidgets('it can start open', (tester) async {
    await tester.pumpWidget(_host(initiallyExpanded: true));

    expect(find.text('body'), findsOneWidget);
  });

  // The chevron is part of the tap target, not a separate control — a member
  // aiming at the arrow must not miss.
  testWidgets('the chevron opens it too', (tester) async {
    await tester.pumpWidget(_host());

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();

    expect(find.text('body'), findsOneWidget);
  });

  // A short summary must still be reachable with a thumb.
  testWidgets('the closed row stays a real tap target', (tester) async {
    await tester.pumpWidget(_host());

    expect(
      tester.getSize(find.byType(InkWell)).height,
      greaterThanOrEqualTo(44),
    );
  });

  testWidgets('it reports its state to assistive tech', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host());

    expect(
      tester.getSemantics(find.byType(InkWell)),
      isSemantics(isButton: true, isExpanded: false),
    );

    await tester.tap(find.text('summary'));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byType(InkWell)),
      isSemantics(isButton: true, isExpanded: true),
    );
    handle.dispose();
  });
}
