import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/features/profile/domain/entities/placement.dart';
import 'package:qeran/features/profile/domain/entities/placement_code.dart';
import 'package:qeran/features/profile/domain/entities/placement_item.dart';
import 'package:qeran/features/profile/domain/entities/placement_item_type.dart';
import 'package:qeran/features/profile/domain/entities/placement_value.dart';
import 'package:qeran/features/profile/presentation/widgets/placement/placement_renderer.dart';
import 'package:qeran/features/profile/presentation/widgets/placement/section_icons.dart';

import '../../../core/shipped_fonts_rig.dart';

/// Run 7, item 4 and Anas's rule for the profile view (own and others'):
/// each section has its own icon and a 16 wine title; rows are 15, questions
/// in the body text's colour and answers in wine, nothing else. A question
/// takes the width it needs and never wraps while room is left; its answer
/// follows on the same line when it fits, on the next line when it doesn't.
PlacementItem _row(int id, String q, String a) => PlacementItem(
  questionId: id,
  question: q,
  type: PlacementItemType.select,
  value: PlacementSingle(a),
  display: PlacementSingle(a),
);

const _short = 'الحالة الاجتماعية';
const _shortAnswer = 'مطلّق';
const _kids = 'هل لديك أطفال؟';
const _kidsAnswer = 'نعم';
const _job = 'كيف تصف وضعك الوظيفي؟';
const _jobAnswer = 'أمتلك عملي الخاص';
const _where = 'أين تفضلين العيش بعد الزواج؟';
const _whereAnswer = 'لا أمانع السكن مؤقتًا مع العائلة';

Future<void> _pump(WidgetTester tester) => pumpOnPhone(
  tester,
  'ar',
  SingleChildScrollView(
    child: PlacementRenderer(
      asCards: true,
      includeNarrative: false,
      placements: [
        Placement(
          code: PlacementCode.defaultGroup,
          name: 'الحياة الزوجية',
          items: [
            _row(1, _short, _shortAnswer),
            _row(2, _job, _jobAnswer),
            _row(4, _kids, _kidsAnswer),
            _row(3, _where, _whereAnswer),
          ],
        ),
      ],
    ),
  ),
);

/// A section from a payload with no `categoryKey` (before Tariq's deploy).
Placement _named(String name) =>
    Placement(code: PlacementCode.defaultGroup, name: name, items: const []);

Rect _rect(WidgetTester tester, String text) => tester.getRect(find.text(text));

/// How many lines [text] was laid out on: one per distinct row of its
/// selection boxes.
int _lines(WidgetTester tester, String text) => tester
    .renderObject<RenderParagraph>(find.text(text))
    .getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: text.length),
    )
    .map((box) => box.top.round())
    .toSet()
    .length;

void main() {
  setUpAll(loadShippedFonts);

  group('the section icon, by name, while no key is sent', () {
    const live = {
      'المعلومات الشخصية': Icons.badge_outlined,
      'Personal Information': Icons.badge_outlined,
      'القيم ونمط الحياة': Icons.mosque_outlined,
      'Values & Lifestyle': Icons.mosque_outlined,
      'الحياة الزوجية': Icons.diversity_1_outlined,
      'Marital Life': Icons.diversity_1_outlined,
      'الوظيفة والدخل': Icons.work_outline_rounded,
      'Work & Income': Icons.work_outline_rounded,
      'عني وعن شريك حياتي': Icons.sticky_note_2_outlined,
      'About Me & My Partner': Icons.sticky_note_2_outlined,
      'السمات الشخصية والاهتمامات': Icons.psychology_outlined,
      'Personality & Interests': Icons.psychology_outlined,
    };

    test('each live category, in both languages, as its key would', () {
      live.forEach((name, icon) {
        expect(sectionIconFor(_named(name)), icon, reason: name);
      });
    });

    test('marks and the tatweel do not hide a name', () {
      expect(
        sectionIconFor(_named('الحياة الزوجيّة')),
        Icons.diversity_1_outlined,
      );
      expect(
        sectionIconFor(_named('الـقيم ونمط الحياة')),
        Icons.mosque_outlined,
      );
    });

    test('a name it does not know keeps the default', () {
      expect(sectionIconFor(_named('بدون تصنيف')), Icons.list_alt_rounded);
      expect(
        sectionIconFor(_named('الدين ونمط الحياة')),
        Icons.list_alt_rounded,
      );
    });
  });

  testWidgets('the title: 16, wine, beside its own icon', (tester) async {
    await _pump(tester);
    final title = tester.widget<Text>(find.text('الحياة الزوجية'));
    expect(title.style?.fontSize, QeranTypography.subtitle.fontSize);
    expect(title.style?.color, QeranColors.wine);
    expect(find.byIcon(Icons.diversity_1_outlined), findsOneWidget);
  });

  testWidgets('rows: 15; questions in the body colour, answers in wine', (
    tester,
  ) async {
    await _pump(tester);
    final question = tester.widget<Text>(find.text(_short));
    final answer = tester.widget<Text>(find.text(_shortAnswer));
    expect(question.style?.fontSize, QeranTypography.body.fontSize);
    expect(answer.style?.fontSize, QeranTypography.body.fontSize);
    expect(question.style?.color, QeranTypography.body.color);
    expect(answer.style?.color, QeranColors.wine);
  });

  testWidgets('an answer that fits follows its question on the line', (
    tester,
  ) async {
    await _pump(tester);
    expect(_rect(tester, _shortAnswer).top, _rect(tester, _short).top);
    expect(_rect(tester, _kidsAnswer).top, _rect(tester, _kids).top);
  });

  testWidgets('one that does not goes under, and the question stays whole', (
    tester,
  ) async {
    await _pump(tester);
    expect(_lines(tester, _where), 1);
    expect(
      _rect(tester, _whereAnswer).top,
      greaterThan(_rect(tester, _where).bottom - 1),
    );
  });

  testWidgets('a question never wraps while room is left on its line', (
    tester,
  ) async {
    await _pump(tester);
    // At 360 this pair doesn't fit one line: the answer goes under, and the
    // question keeps its line whole (it used to wrap beside the answer).
    expect(_lines(tester, _job), 1);
    expect(
      _rect(tester, _jobAnswer).top,
      greaterThan(_rect(tester, _job).bottom - 1),
    );
    expect(_lines(tester, _short), 1);
  });
}
