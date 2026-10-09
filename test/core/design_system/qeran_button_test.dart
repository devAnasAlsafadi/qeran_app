import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
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

  // D1 / Q11: the 40 pt xs and 36 pt sm are gone; these are all there is.
  testWidgets('the sizes: lg 54, md 46, compact 48', (tester) async {
    final heights = <QeranButtonSize, double>{};
    for (final size in QeranButtonSize.values) {
      await _pump(tester, size);
      heights[size] = tester.getSize(find.byType(QeranButton)).height;
    }

    expect(heights, {
      QeranButtonSize.lg: 54,
      QeranButtonSize.md: 46,
      QeranButtonSize.compact: 48,
    });
  });

  // The photo-exchange pair measures its labels with compact's dense look
  // (xs's before D1): the label type, 8 pt sides, a 16 pt icon.
  testWidgets('compact keeps the dense look', (tester) async {
    final compact = await _looks(tester, QeranButtonSize.compact);

    expect(compact.style?.fontSize, QeranTypography.label.fontSize);
    expect(compact.padding.resolve(TextDirection.ltr).left, QeranSpacing.s8);
    expect(compact.icon, 16);
  });
}
