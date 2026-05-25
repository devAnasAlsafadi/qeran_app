import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/questionnaire/domain/entities/question_entity.dart';
import 'package:qeran/features/questionnaire/presentation/screens/questionnaire_flow/widgets/category_progress_calculator.dart';

QuestionEntity _q(String categoryName, {String id = ''}) => QuestionEntity(
      questionId: id.isEmpty ? categoryName : id,
      text: 'q',
      type: QuestionType.radio,
      options: const [],
      categoryName: categoryName,
    );

void main() {
  group('CategoryProgressCalculator.buildSteps', () {
    test('returns empty list for empty questions', () {
      final steps = CategoryProgressCalculator.buildSteps([]);
      expect(steps, isEmpty);
    });

    test('single category for all questions → one step spanning full range',
        () {
      final questions = [_q('A', id: '1'), _q('A', id: '2'), _q('A', id: '3')];
      final steps = CategoryProgressCalculator.buildSteps(questions);
      expect(steps.length, 1);
      expect(steps[0].name, 'A');
      expect(steps[0].firstIndex, 0);
      expect(steps[0].lastIndex, 2);
    });

    test('two categories → two steps with correct index boundaries', () {
      final questions = [
        _q('A', id: '1'),
        _q('A', id: '2'),
        _q('A', id: '3'),
        _q('B', id: '4'),
        _q('B', id: '5'),
      ];
      final steps = CategoryProgressCalculator.buildSteps(questions);
      expect(steps.length, 2);
      expect(steps[0].name, 'A');
      expect(steps[0].firstIndex, 0);
      expect(steps[0].lastIndex, 2);
      expect(steps[1].name, 'B');
      expect(steps[1].firstIndex, 3);
      expect(steps[1].lastIndex, 4);
    });

    test('non-contiguous repeats (A,A,B,A) → three separate steps', () {
      final questions = [
        _q('A', id: '1'),
        _q('A', id: '2'),
        _q('B', id: '3'),
        _q('A', id: '4'),
      ];
      final steps = CategoryProgressCalculator.buildSteps(questions);
      expect(steps.length, 3);
      expect(steps[0].name, 'A');
      expect(steps[0].firstIndex, 0);
      expect(steps[0].lastIndex, 1);
      expect(steps[1].name, 'B');
      expect(steps[1].firstIndex, 2);
      expect(steps[1].lastIndex, 2);
      expect(steps[2].name, 'A');
      expect(steps[2].firstIndex, 3);
      expect(steps[2].lastIndex, 3);
    });
  });

  group('CategoryProgressCalculator.statusOf', () {
    const step = CategoryStep(name: 'A', firstIndex: 2, lastIndex: 4);

    test('index before firstIndex → upcoming', () {
      expect(
        CategoryProgressCalculator.statusOf(step, 1),
        CategoryStepStatus.upcoming,
      );
    });

    test('index == firstIndex → current', () {
      expect(
        CategoryProgressCalculator.statusOf(step, 2),
        CategoryStepStatus.current,
      );
    });

    test('index in middle of range → current', () {
      expect(
        CategoryProgressCalculator.statusOf(step, 3),
        CategoryStepStatus.current,
      );
    });

    test('index == lastIndex → current', () {
      expect(
        CategoryProgressCalculator.statusOf(step, 4),
        CategoryStepStatus.current,
      );
    });

    test('index after lastIndex → completed', () {
      expect(
        CategoryProgressCalculator.statusOf(step, 5),
        CategoryStepStatus.completed,
      );
    });
  });
}
