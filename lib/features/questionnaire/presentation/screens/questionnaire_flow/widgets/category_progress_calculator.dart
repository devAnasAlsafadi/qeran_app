import 'package:qeran/features/questionnaire/domain/entities/question_entity.dart';

/// A contiguous run of questions sharing the same [QuestionEntity.categoryName].
class CategoryStep {
  final String name;
  final int firstIndex; // inclusive
  final int lastIndex; // inclusive

  const CategoryStep({
    required this.name,
    required this.firstIndex,
    required this.lastIndex,
  });

  bool contains(int questionIndex) =>
      questionIndex >= firstIndex && questionIndex <= lastIndex;
}

enum CategoryStepStatus { completed, current, upcoming }

class CategoryProgressCalculator {
  const CategoryProgressCalculator._();

  /// Walk [questions] once, grouping consecutive entries with the same
  /// `categoryName` into a single [CategoryStep]. Preserves API order.
  /// Two non-adjacent runs with the same name produce two separate steps.
  static List<CategoryStep> buildSteps(List<QuestionEntity> questions) {
    if (questions.isEmpty) return const [];
    final result = <CategoryStep>[];
    String currentName = questions[0].categoryName;
    int runStart = 0;
    for (int i = 1; i < questions.length; i++) {
      final name = questions[i].categoryName;
      if (name != currentName) {
        result.add(CategoryStep(
          name: currentName,
          firstIndex: runStart,
          lastIndex: i - 1,
        ));
        currentName = name;
        runStart = i;
      }
    }
    result.add(CategoryStep(
      name: currentName,
      firstIndex: runStart,
      lastIndex: questions.length - 1,
    ));
    return result;
  }

  /// Classify a step relative to the live [currentQuestionIndex].
  static CategoryStepStatus statusOf(
    CategoryStep step,
    int currentQuestionIndex,
  ) {
    if (currentQuestionIndex > step.lastIndex) {
      return CategoryStepStatus.completed;
    }
    if (step.contains(currentQuestionIndex)) {
      return CategoryStepStatus.current;
    }
    return CategoryStepStatus.upcoming;
  }
}
