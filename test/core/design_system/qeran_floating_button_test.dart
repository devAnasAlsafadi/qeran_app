import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_floating_button.dart';

void main() {
  testWidgets('a gold pill, 56 high, wine icon and label; a tap runs it', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: QeranFloatingButton(
            label: 'New post',
            icon: Icons.edit_square,
            onPressed: () => taps++,
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(QeranFloatingButton)).height, 56);
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(QeranFloatingButton),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, QeranColors.gold);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.edit_square)).color,
      QeranColors.wine,
    );
    expect(
      tester.widget<Text>(find.text('New post')).style?.color,
      QeranColors.wine,
    );

    await tester.tap(find.text('New post'));
    expect(taps, 1);
  });

  testWidgets('the room a list keeps for it includes the safe area', (
    tester,
  ) async {
    late BuildContext inside;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
        child: Builder(
          builder: (context) {
            inside = context;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(QeranFloatingButton.clearance(inside), 56 + 32 + 34);
  });
}
