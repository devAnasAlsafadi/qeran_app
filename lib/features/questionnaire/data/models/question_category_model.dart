import 'question_model.dart';

/// Represents one category entry in the API response:
/// ```json
/// {
///   "categoryId": 1,
///   "categoryName": "المعلومات الشخصية",
///   "questions": [ ... ]
/// }
/// ```
///
/// Responsible for flattening the nested structure by injecting
/// [categoryName] into each [QuestionModel] it creates.
class QuestionCategoryModel {
  final int categoryId;
  final String categoryName;
  final List<QuestionModel> questions;

  const QuestionCategoryModel({
    required this.categoryId,
    required this.categoryName,
    required this.questions,
  });

  factory QuestionCategoryModel.fromJson(Map<String, dynamic> json) {
    final categoryName = json['categoryName'] as String? ?? '';
    final rawQuestions = json['questions'] as List<dynamic>? ?? [];

    return QuestionCategoryModel(
      categoryId: json['categoryId'] as int? ?? 0,
      categoryName: categoryName,
      questions: rawQuestions
          .map(
            (q) => QuestionModel.fromJson(
              q as Map<String, dynamic>,
              categoryName: categoryName,
            ),
          )
          .toList(),
    );
  }
}
