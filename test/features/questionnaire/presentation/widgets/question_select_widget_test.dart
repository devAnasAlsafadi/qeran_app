import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/features/questionnaire/domain/entities/question_entity.dart';
import 'package:qeran/features/questionnaire/domain/entities/question_option_entity.dart';
import 'package:qeran/features/questionnaire/presentation/widgets/question_select_widget.dart';

/// Baseline for the single-select list. Written when the option row was
/// extracted, BEFORE search was added, so the search sub-step has something to
/// prove itself against — the widget had no coverage at all until now.
QuestionEntity _question(List<String> labels) => QuestionEntity(
  questionId: 'q1',
  text: 'Nationality',
  type: QuestionType.select,
  options: [
    for (var i = 0; i < labels.length; i++)
      QuestionOptionEntity(id: 'opt-$i', text: labels[i]),
  ],
);

Future<List<String>> _pump(
  WidgetTester tester, {
  required List<String> labels,
  String? selectedId,
}) async {
  final tapped = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: QuestionSelectWidget(
            question: _question(labels),
            selectedOptionId: selectedId,
            onChanged: tapped.add,
          ),
        ),
      ),
    ),
  );
  return tapped;
}

void main() {
  testWidgets('draws one row per option the backend sent', (tester) async {
    await _pump(tester, labels: ['Jordan', 'Armenia', 'Estonia']);

    expect(find.text('Jordan'), findsOneWidget);
    expect(find.text('Armenia'), findsOneWidget);
    expect(find.text('Estonia'), findsOneWidget);
  });

  testWidgets('a tap reports the option id, not its label', (tester) async {
    final tapped = await _pump(tester, labels: ['Jordan', 'Armenia']);

    await tester.tap(find.text('Armenia'));

    expect(tapped, ['opt-1']);
  });

  testWidgets('the chosen option is the only one drawn as chosen', (
    tester,
  ) async {
    await _pump(tester, labels: ['Jordan', 'Armenia'], selectedId: 'opt-1');

    // Weight is what separates them; asserted by style rather than by pixels
    // so the shipped font cannot change the answer.
    final chosen = tester.widget<Text>(find.text('Armenia'));
    final other = tester.widget<Text>(find.text('Jordan'));
    expect(chosen.style, QeranTypography.subtitle);
    expect(other.style, QeranTypography.body);
  });

  testWidgets('nothing selected draws every row unchosen', (tester) async {
    await _pump(tester, labels: ['Jordan', 'Armenia']);

    expect(
      tester.widget<Text>(find.text('Jordan')).style,
      QeranTypography.body,
    );
    expect(
      tester.widget<Text>(find.text('Armenia')).style,
      QeranTypography.body,
    );
  });
}
