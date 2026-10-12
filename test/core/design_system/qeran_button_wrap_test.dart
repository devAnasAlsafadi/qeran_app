import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_button_row.dart';

import '../shipped_fonts_rig.dart';

/// Run 6: no button label is ever cut. A label wider than its slot wraps onto
/// a second line and the button grows; the font never shrinks, and nothing is
/// ever ellipsized. Two side by side keep one height.

const _long = 'Send your questions to the matchmaker';

RenderParagraph _label(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text));

void main() {
  setUpAll(loadShippedFonts);

  for (final size in QeranButtonSize.values) {
    testWidgets('a long label wraps, whole, and grows the button [$size]', (
      tester,
    ) async {
      await pumpOnPhone(
        tester,
        'en',
        SizedBox(
          // Where it takes exactly two lines: compact's type is smaller.
          width: size == QeranButtonSize.compact ? 200 : 320,
          child: QeranButton(
            label: _long,
            onPressed: () {},
            size: size,
            leadingIcon: Icons.chat_bubble_outline_rounded,
          ),
        ),
      );

      final label = _label(tester, _long);
      expect(label.didExceedMaxLines, isFalse);
      expect(label.maxLines, isNull);
      expect(label.overflow, isNot(TextOverflow.ellipsis));
      // Two lines: twice what it takes on one unbounded line.
      final oneLine = label.getMaxIntrinsicHeight(double.infinity);
      expect(label.size.height, closeTo(2 * oneLine, 1));
      final minimum = size == QeranButtonSize.lg ? 54.0 : 48.0;
      final height = tester.getSize(find.byType(QeranButton)).height;
      expect(height, greaterThanOrEqualTo(minimum));
      // Its lines keep s8 above and below, as one line keeps its centring.
      expect(
        height,
        greaterThanOrEqualTo(label.size.height + 2 * QeranSpacing.s8),
      );
    });
  }

  testWidgets('a second line makes the button taller than one line does', (
    tester,
  ) async {
    await pumpOnPhone(
      tester,
      'en',
      SizedBox(
        width: 200,
        child: QeranButton(label: _long, onPressed: () {}),
      ),
    );

    expect(tester.getSize(find.byType(QeranButton)).height, greaterThan(54));
  });

  testWidgets('the font is the button\'s own, never scaled down', (
    tester,
  ) async {
    await pumpOnPhone(
      tester,
      'en',
      SizedBox(
        width: 120,
        child: QeranButton(label: _long, onPressed: () {}),
      ),
    );

    expect(find.byType(FittedBox), findsNothing);
    final label = _label(tester, _long);
    expect(label.text.style?.fontSize, 16);
    expect(label.textScaler.scale(16), 16);
    // Nothing between the label and the screen scales it either.
    expect(
      find.ancestor(of: find.text(_long), matching: find.byType(Transform)),
      findsNothing,
    );
  });

  testWidgets('loading keeps a wrapped label\'s height, so nothing jumps', (
    tester,
  ) async {
    Widget button({required bool loading}) => SizedBox(
      width: 200,
      child: QeranButton(label: _long, onPressed: () {}, loading: loading),
    );
    await pumpOnPhone(tester, 'en', button(loading: false));
    final idle = tester.getSize(find.byType(QeranButton)).height;

    await pumpOnPhone(tester, 'en', button(loading: true));

    expect(tester.getSize(find.byType(QeranButton)).height, idle);
  });

  testWidgets('a pair shares one height when only one label wraps', (
    tester,
  ) async {
    await pumpOnPhone(
      tester,
      'en',
      SizedBox(
        width: 320,
        child: QeranButtonRow(
          children: [
            QeranButton(label: 'Pass', onPressed: () {}),
            QeranButton(label: _long, onPressed: () {}),
          ],
        ),
      ),
    );

    final heights = tester
        .widgetList<QeranButton>(find.byType(QeranButton))
        .map((b) => tester.getSize(find.byWidget(b)).height)
        .toSet();
    expect(heights, hasLength(1));
    expect(heights.single, greaterThan(54));
  });
}
