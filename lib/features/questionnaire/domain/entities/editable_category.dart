import 'package:equatable/equatable.dart';

import 'editable_question.dart';

/// A category group on the profile-edit form. `categoryId == 0` is the
/// "أخرى" bucket (questions with no active category). The edit screen
/// groups purely by category and ignores per-question placement.
class EditableCategory extends Equatable {
  final int categoryId;
  final String categoryName;
  final List<EditableQuestion> questions;

  const EditableCategory({
    required this.categoryId,
    required this.categoryName,
    required this.questions,
  });

  @override
  List<Object?> get props => [categoryId, categoryName, questions];
}
