import 'package:equatable/equatable.dart';

class QuestionOptionEntity extends Equatable {
  final String id;
  final String text;

  const QuestionOptionEntity({required this.id, required this.text});

  @override
  List<Object?> get props => [id, text];
}
