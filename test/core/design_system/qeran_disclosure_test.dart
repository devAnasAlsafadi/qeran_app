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

  group('controlled', () {
    testWidgets('it draws what it is told, not what it was tapped into', (
      tester,
    ) async {
      // A caller that ignores the callback pins the row shut. That is the
      // guarantee single-open coordination rests on: no local state can
      // disagree with the owner, even for one frame.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QeranDisclosure(
              expanded: false,
              onExpandedChanged: (_) {},
              summary: const Text('summary'),
              child: const Text('body'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('summary'));
      await tester.pumpAndSettle();

      expect(find.text('body'), findsNothing);
    });

    testWidgets('a tap reports the value it is asking for', (tester) async {
      final asked = <bool>[];
      Widget host(bool expanded) => MaterialApp(
        home: Scaffold(
          body: QeranDisclosure(
            expanded: expanded,
            onExpandedChanged: asked.add,
            summary: const Text('summary'),
            child: const Text('body'),
          ),
        ),
      );

      await tester.pumpWidget(host(false));
      await tester.tap(find.text('summary'));
      await tester.pumpAndSettle();
      expect(asked, [true]);

      await tester.pumpWidget(host(true));
      expect(find.text('body'), findsOneWidget);

      await tester.tap(find.text('summary'));
      await tester.pumpAndSettle();
      expect(asked, [true, false]);
    });

    // initiallyExpanded is for the uncontrolled case only; a controlled
    // widget that honoured it would open against its owner's wishes.
    testWidgets('an explicit value beats initiallyExpanded', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QeranDisclosure(
              initiallyExpanded: true,
              expanded: false,
              onExpandedChanged: (_) {},
              summary: const Text('summary'),
              child: const Text('body'),
            ),
          ),
        ),
      );

      expect(find.text('body'), findsNothing);
    });
  });

  group('hint', () {
    Widget hosted({bool? expanded}) => MaterialApp(
      home: Scaffold(
        body: QeranDisclosure(
          hint: 'see more',
          expanded: expanded,
          onExpandedChanged: expanded == null ? null : (_) {},
          summary: const Text('summary'),
          child: const Text('body'),
        ),
      ),
    );

    testWidgets('it says what opening the row reveals', (tester) async {
      await tester.pumpWidget(hosted());

      expect(find.textContaining('see more'), findsOneWidget);
    });

    // Having said it once it stops: the member has learned the row opens, and
    // the expanded row is busy enough without a standing instruction.
    testWidgets('it goes away once open', (tester) async {
      await tester.pumpWidget(hosted());

      await tester.tap(find.text('summary'));
      await tester.pumpAndSettle();

      expect(find.textContaining('see more'), findsNothing);
    });

    testWidgets('a row that starts open never shows it', (tester) async {
      await tester.pumpWidget(hosted(expanded: true));

      expect(find.textContaining('see more'), findsNothing);
    });

    testWidgets('no hint, no extra text', (tester) async {
      await tester.pumpWidget(_host());

      expect(find.text('summary'), findsOneWidget);
      expect(find.textContaining('·'), findsNothing);
    });

    // The hint is part of the row, so aiming at it must open the row rather
    // than land on dead space.
    testWidgets('tapping the hint opens the row', (tester) async {
      await tester.pumpWidget(hosted());

      await tester.tap(find.textContaining('see more'));
      await tester.pumpAndSettle();

      expect(find.text('body'), findsOneWidget);
    });
  });
}
