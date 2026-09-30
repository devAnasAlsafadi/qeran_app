import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_count_badge.dart';

/// A capped count is a figure, not prose: `99+` means "more than 99" in every
/// language. Left to the ambient direction it does NOT survive Arabic — the
/// trailing `+` is a neutral next to the paragraph's RTL edge, so the bidi
/// algorithm draws it to the LEFT of the digits and the bell reads `+99`.
///
/// These tests pin the DISPLAYED order rather than the widget's
/// `textDirection` field, so they still fail if the fix is later reverted by
/// some other route (a wrapping direction, a different string shape).
void main() {
  Future<void> pump(WidgetTester tester, TextDirection direction) =>
      tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: const Scaffold(
              body: Center(child: QeranCountBadge(count: 100)),
            ),
          ),
        ),
      );

  /// Left edge of the glyphs for `text[start..end]` as actually laid out.
  double leftEdgeOf(WidgetTester tester, int start, int end) {
    final paragraph = tester.renderObject<RenderParagraph>(find.text('99+'));
    return paragraph
        .getBoxesForSelection(
          TextSelection(baseOffset: start, extentOffset: end),
        )
        .first
        .toRect()
        .left;
  }

  // '99+' → index 0 is the first digit, index 2 is the plus.
  double digitsLeft(WidgetTester tester) => leftEdgeOf(tester, 0, 1);
  double plusLeft(WidgetTester tester) => leftEdgeOf(tester, 2, 3);

  testWidgets('reads 99+ in Arabic, not +99', (tester) async {
    await pump(tester, TextDirection.rtl);

    expect(
      plusLeft(tester),
      greaterThan(digitsLeft(tester)),
      reason:
          'the plus must be drawn to the RIGHT of the digits — '
          'reversed, the bell reads "+99"',
    );
  });

  testWidgets('reads 99+ in English too', (tester) async {
    await pump(tester, TextDirection.ltr);

    expect(
      plusLeft(tester),
      greaterThan(digitsLeft(tester)),
      reason: 'guards the fix against being pinned to rtl only',
    );
  });
}
