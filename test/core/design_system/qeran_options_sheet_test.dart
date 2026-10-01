import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_options_sheet.dart';

const _options = [
  QeranOption(icon: Icons.flag_outlined, label: 'Report', value: 'report'),
  QeranOption(
    icon: Icons.delete_outline_rounded,
    label: 'Delete',
    value: 'delete',
    danger: true,
  ),
];

/// Opens the sheet from a button and keeps what it resolves to.
Future<void> _open(
  WidgetTester tester, {
  TextDirection direction = TextDirection.ltr,
  required void Function(String?) resolved,
}) async {
  await tester.pumpWidget(MaterialApp(
    builder: (_, child) => Directionality(textDirection: direction, child: child!),
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async =>
              resolved(await QeranOptionsSheet.show(context, options: _options)),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('one row per option, in order; a tap resolves to its value',
      (tester) async {
    String? result;
    await _open(tester, resolved: (v) => result = v);

    expect(tester.getTopLeft(find.text('Report')).dy,
        lessThan(tester.getTopLeft(find.text('Delete')).dy));
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(result, 'delete');
    expect(find.text('Report'), findsNothing);
  });

  testWidgets('a danger row is painted in the danger colour, the rest wine',
      (tester) async {
    await _open(tester, resolved: (_) {});

    expect(tester.widget<Text>(find.text('Delete')).style?.color,
        QeranColors.danger);
    expect(tester.widget<Icon>(find.byIcon(Icons.flag_outlined)).color,
        QeranColors.wine);
  });

  testWidgets('dismissing resolves to null', (tester) async {
    String? result = 'untouched';
    await _open(tester, resolved: (v) => result = v);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });

  testWidgets('right to left, the icon leads from the right', (tester) async {
    await _open(tester, direction: TextDirection.rtl, resolved: (_) {});

    final icon = tester.getCenter(find.byIcon(Icons.flag_outlined)).dx;
    final label = tester.getCenter(find.text('Report')).dx;
    expect(icon, greaterThan(label));
  });
}
