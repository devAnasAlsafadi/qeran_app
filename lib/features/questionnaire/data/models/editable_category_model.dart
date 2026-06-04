import '../../domain/entities/editable_category.dart';
import 'editable_question_model.dart';

class EditableCategoryModel {
  final int categoryId;
  final String categoryName;
  final List<EditableQuestionModel> questions;

  const EditableCategoryModel({
    required this.categoryId,
    required this.categoryName,
    required this.questions,
  });

  factory EditableCategoryModel.fromJson(Map<String, dynamic> json) {
    final questionsList = json['questions'] as List<dynamic>? ?? [];
    return EditableCategoryModel(
      categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
      categoryName: json['categoryName'] as String? ?? '',
      questions: questionsList
          .map((q) =>
              EditableQuestionModel.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }

  EditableCategory toEntity() {
    return EditableCategory(
      categoryId: categoryId,
      categoryName: categoryName,
      questions: questions.map((q) => q.toEntity()).toList(),
    );
  }
}
