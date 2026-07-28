import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_sheet.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';

/// The keyboard shrinks a sheet's available height (the scaffold pads by
/// `viewInsets.bottom`). A fixed-height body cannot absorb that and overflows —
/// this is the "RenderFlex overflowed by 51 pixels" reported on the matchmaker
/// notes sheet. `scrollableBody: true` is the fix, and these tests pin it.

/// A body tall enough that it cannot fit once the keyboard is up.
Widget _tallBody() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    const Text('subtitle'),
    QeranTextField(controller: TextEditingController(), maxLines: 6),
    const SizedBox(height: 120),
    const SizedBox(height: 120),
    const SizedBox(height: 120),
  ],
);

Widget _host({
  required bool scrollableBody,
  required double keyboardInset,
  TextDirection direction = TextDirection.rtl,
}) {
  return MaterialApp(
    locale: const Locale('ar'),
    home: Builder(
      builder: (context) => MediaQuery(
        // Only viewInsets is overridden — the surface size comes from
        // setSurfaceSize so the real layout constraints shrink too.
        data: MediaQuery.of(
          context,
        ).copyWith(viewInsets: EdgeInsets.only(bottom: keyboardInset)),
        child: Directionality(
          textDirection: direction,
          // QeranTextField needs a Material ancestor.
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: QeranBottomSheetScaffold(
                title: 'ملاحظات',
                scrollableBody: scrollableBody,
                body: _tallBody(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  // A phone-sized surface, so a 400px keyboard genuinely squeezes the sheet.
  // The default 800x600 test surface is too roomy to reproduce the overflow.
  Future<void> phoneSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('scrollableBody survives a raised keyboard without overflowing', (
    tester,
  ) async {
    await phoneSurface(tester);
    await tester.pumpWidget(
      _host(scrollableBody: true, keyboardInset: 400),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('scrollableBody also holds in LTR', (tester) async {
    await phoneSurface(tester);
    await tester.pumpWidget(
      _host(
        scrollableBody: true,
        keyboardInset: 400,
        direction: TextDirection.ltr,
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('scrollableBody is a no-op layer when no keyboard is up', (
    tester,
  ) async {
    await phoneSurface(tester);
    await tester.pumpWidget(_host(scrollableBody: true, keyboardInset: 0));

    expect(tester.takeException(), isNull);
  });

  testWidgets('the default (non-scrollable) body still overflows — the bug '
      'this flag exists to fix', (tester) async {
    await phoneSurface(tester);
    await tester.pumpWidget(
      _host(scrollableBody: false, keyboardInset: 400),
    );

    // Documents WHY every input sheet must opt in: without the flag the same
    // content raises the overflow this batch was fixing.
    expect(tester.takeException(), isNotNull);
  });

  testWidgets('a scrollable body is not double-wrapped', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: QeranBottomSheetScaffold(
              title: 'مشاركة',
              // Default false — bodies that own their scrolling (or use
              // Expanded) must NOT be wrapped or they lose their bounds.
              body: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(child: ListView(children: const [Text('a')])),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsNothing);
  });
}
