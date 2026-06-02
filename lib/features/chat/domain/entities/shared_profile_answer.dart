import 'package:equatable/equatable.dart';

/// A single fact shown on the shared-profile card (e.g. nationality,
/// profession). Backend ships these in `sharedProfile.answers[]`.
class SharedProfileAnswer extends Equatable {
  final int questionId;
  final String question;
  final String answer;

  const SharedProfileAnswer({
    required this.questionId,
    required this.question,
    required this.answer,
  });

  @override
  List<Object?> get props => [questionId, question, answer];
}
