import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_monogram.dart';
import 'package:qeran/core/design_system/widgets/qeran_own_text.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';

/// [child] in a UI of [direction] (the app's language).
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
}) =>
    tester.pumpWidget(Directionality(
      textDirection: direction,
      child: Center(child: child),
    ));

RichText _rich(WidgetTester tester) =>
    tester.widget<RichText>(find.byType(RichText).first);

/// The direction the text is actually laid out in — its own, or the UI's.
TextDirection _laidOut(WidgetTester tester) => tester
    .renderObject<RenderParagraph>(find.byType(RichText).first)
    .textDirection;

void main() {
  group('QeranOwnText (D13)', () {
    testWidgets('Arabic text in the English UI: right to left, Noto Kufi Arabic',
        (tester) async {
      await _pump(tester, const QeranOwnText('أم عبدالرحمن الشمّري'));

      expect(_laidOut(tester), TextDirection.rtl);
      expect(_rich(tester).text.style?.fontFamily, 'NotoKufiArabic');
    });

    testWidgets('English text in the Arabic UI: left to right, Montserrat',
        (tester) async {
      await _pump(tester, const QeranOwnText('Very helpful, thank you.'),
          direction: TextDirection.rtl);

      expect(_laidOut(tester), TextDirection.ltr);
      expect(_rich(tester).text.style?.fontFamily, 'Montserrat');
    });

    testWidgets("no letters: the UI's direction, the style's own font",
        (tester) async {
      await _pump(tester, const QeranOwnText('128', style: TextStyle(fontSize: 9)),
          direction: TextDirection.rtl);

      expect(_laidOut(tester), TextDirection.rtl);
      expect(_rich(tester).text.style?.fontFamily, isNull);
      expect(_rich(tester).text.style?.fontSize, 9);
    });

    testWidgets('the rest of the style is kept', (tester) async {
      await _pump(
        tester,
        const QeranOwnText('هدى',
            style: TextStyle(fontSize: 15, color: QeranColors.wine),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      );

      final rich = _rich(tester);
      expect(rich.text.style?.fontSize, 15);
      expect(rich.text.style?.color, QeranColors.wine);
      expect((rich.maxLines, rich.overflow), (1, TextOverflow.ellipsis));
    });
  });

  group('QeranMonogram', () {
    BoxDecoration decoration(WidgetTester tester) => tester
        .widget<Container>(find.byType(Container).first)
        .decoration! as BoxDecoration;

    testWidgets('brand: wine disc, gold ring, gold initial', (tester) async {
      await _pump(tester, const QeranMonogram(name: 'هدى'));

      expect(decoration(tester).color, QeranColors.wine);
      expect(decoration(tester).border, isNotNull);
      expect(_rich(tester).text.style?.color, QeranColors.gold);
    });

    testWidgets('plain: cream disc, no ring, wine initial (members, D10)',
        (tester) async {
      await _pump(tester,
          const QeranMonogram(name: 'سارة', tone: QeranMonogramTone.plain));

      expect(decoration(tester).color, QeranColors.creamSurface);
      expect(decoration(tester).border, isNull);
      expect(_rich(tester).text.style?.color, QeranColors.wine);
    });

    testWidgets("the initial is drawn in its own script's font", (tester) async {
      await _pump(tester, const QeranMonogram(name: 'سارة'));
      expect(_rich(tester).text.style?.fontFamily, 'NotoKufiArabic');

      await _pump(tester, const QeranMonogram(name: 'dima'),
          direction: TextDirection.rtl);
      expect(_rich(tester).text.style?.fontFamily, 'Montserrat');
      expect(find.text('D'), findsOneWidget);
    });

    testWidgets('no name: the person glyph, in the tone colour', (tester) async {
      await _pump(tester,
          const QeranMonogram(name: ' ', tone: QeranMonogramTone.plain));

      expect(tester.widget<Icon>(find.byIcon(Icons.person_outline)).color,
          QeranColors.wine);
    });
  });
}
