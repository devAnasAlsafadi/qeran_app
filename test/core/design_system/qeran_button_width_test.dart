import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';

/// [child] in a 300-wide box, in [direction].
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
}) => tester.pumpWidget(
  MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: Center(child: SizedBox(width: 300, child: child)),
    ),
  ),
);

QeranButton _button({
  String label = 'Try again',
  bool fullWidth = false,
  bool loading = false,
  QeranButtonSize size = QeranButtonSize.lg,
}) => QeranButton(
  label: label,
  onPressed: () {},
  fullWidth: fullWidth,
  loading: loading,
  size: size,
  leadingIcon: Icons.refresh_rounded,
);

Rect _rect(WidgetTester tester) => tester.getRect(find.byType(QeranButton));

/// The label and its icon — what the button hugs.
double _content(WidgetTester tester) => tester
    .getSize(
      find.descendant(of: find.byType(QeranButton), matching: find.byType(Row)),
    )
    .width;

void main() {
  testWidgets('without fullWidth, in a column: as wide as its label and its '
      'side padding, centred', (tester) async {
    await _pump(tester, Column(children: [_button()]));

    expect(_rect(tester).width, _content(tester) + 2 * 24);
    expect(_rect(tester).center.dx, 400);
  });

  testWidgets('without fullWidth, aligned to the start: at the start edge, in '
      'either direction', (tester) async {
    Widget start() =>
        Align(alignment: AlignmentDirectional.centerStart, child: _button());

    await _pump(tester, start());
    expect(_rect(tester).left, 250);

    await _pump(tester, start(), direction: TextDirection.rtl);
    expect(_rect(tester).right, 550);
  });

  testWidgets('a short label: never narrower than the 48 pt tap target', (
    tester,
  ) async {
    await _pump(
      tester,
      const Column(
        children: [
          QeranButton(
            label: 'OK',
            onPressed: null,
            fullWidth: false,
            size: QeranButtonSize.compact,
          ),
        ],
      ),
    );

    expect(_rect(tester).width, QeranButton.minTapWidth);
    expect(_rect(tester).height, 48);
  });

  testWidgets('fullWidth (the default): the whole width', (tester) async {
    await _pump(tester, Column(children: [_button(fullWidth: true)]));

    expect(_rect(tester).width, 300);
  });

  testWidgets('given its width (an Expanded), it takes it either way', (
    tester,
  ) async {
    await _pump(tester, Row(children: [Expanded(child: _button())]));

    expect(_rect(tester).width, 300);
  });

  testWidgets('loading: keeps its label\'s width, so nothing moves', (
    tester,
  ) async {
    await _pump(tester, Column(children: [_button()]));
    final idle = _rect(tester).width;

    await _pump(tester, Column(children: [_button(loading: true)]));

    expect(_rect(tester).width, idle);
  });
}
