import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';

Future<void> _pump(WidgetTester tester, QeranButtonSize size) =>
    tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 240,
            child: QeranButton(
              label: 'أرسل استفساراتك',
              onPressed: () {},
              size: size,
              trailingIcon: Icons.check_rounded,
            ),
          ),
        ),
      ),
    );

/// Everything about a size except its height: the label's style, the side
/// padding and the icon's size.
Future<({TextStyle? style, EdgeInsetsGeometry padding, double? icon})> _looks(
  WidgetTester tester,
  QeranButtonSize size,
) async {
  await _pump(tester, size);
  final padding = tester.widget<Padding>(
    find
        .ancestor(of: find.byType(Row), matching: find.byType(Padding))
        .first,
  );
  return (
    style: tester.widget<Text>(find.text('أرسل استفساراتك')).style,
    padding: padding.padding,
    icon: tester.widget<Icon>(find.byIcon(Icons.check_rounded)).size,
  );
}

void main() {
  testWidgets('compact is 48 pt tall — the full tap target', (tester) async {
    await _pump(tester, QeranButtonSize.compact);

    expect(tester.getSize(find.byType(QeranButton)).height, 48);
  });

  testWidgets('xs stays 40 pt, for the matchmaker app until its sweep', (
    tester,
  ) async {
    await _pump(tester, QeranButtonSize.xs);

    expect(tester.getSize(find.byType(QeranButton)).height, 40);
  });

  // The photo-exchange pair measures its labels with xs's padding; compact
  // must not move that measurement.
  testWidgets('compact looks like xs in everything but height', (
    tester,
  ) async {
    final xs = await _looks(tester, QeranButtonSize.xs);
    final compact = await _looks(tester, QeranButtonSize.compact);

    expect(compact.style, xs.style);
    expect(compact.padding, xs.padding);
    expect(compact.icon, xs.icon);
  });
}
