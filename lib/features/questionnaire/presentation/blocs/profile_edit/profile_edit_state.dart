import 'package:equatable/equatable.dart';

import '../../../domain/entities/editable_category.dart';

/// One-shot outcomes the screen listens for (snackbars). The screen reacts
/// on [ProfileEditLoaded.eventVersion] changing, never on the enum alone.
enum ProfileEditEvent { none, validationError, saveSuccess, saveFailure }

sealed class ProfileEditState extends Equatable {
  const ProfileEditState();

  @override
  List<Object?> get props => const [];
}

final class ProfileEditInitial extends ProfileEditState {
  const ProfileEditInitial();
}

final class ProfileEditLoading extends ProfileEditState {
  const ProfileEditLoading();
}

final class ProfileEditLoaded extends ProfileEditState {
  final List<EditableCategory> categories;

  /// Current working answers keyed by questionId. Shapes mirror what
  /// `QuestionRenderer`/`ProfileEditRenderer` expect: select/radio → `String?`,
  /// checkbox/interests → `List<String>`, date → `DateTime?`,
  /// height/weight → `int?`, text → `String?`.
  final Map<String, dynamic> answers;

  /// Required questions that failed validation on the last save attempt.
  final Set<String> invalidIds;

  /// True while the submit request is in flight.
  final bool submitting;

  final ProfileEditEvent event;
  final int eventVersion;
  final String? eventMessage;

  const ProfileEditLoaded({
    required this.categories,
    required this.answers,
    this.invalidIds = const {},
    this.submitting = false,
    this.event = ProfileEditEvent.none,
    this.eventVersion = 0,
    this.eventMessage,
  });

  ProfileEditLoaded copyWith({
    Map<String, dynamic>? answers,
    Set<String>? invalidIds,
    bool? submitting,
    ProfileEditEvent? event,
    int? eventVersion,
    String? eventMessage,
  }) {
    return ProfileEditLoaded(
      categories: categories,
      answers: answers ?? this.answers,
      invalidIds: invalidIds ?? this.invalidIds,
      submitting: submitting ?? this.submitting,
      event: event ?? this.event,
      eventVersion: eventVersion ?? this.eventVersion,
      eventMessage: eventMessage ?? this.eventMessage,
    );
  }

  @override
  List<Object?> get props => [
        categories,
        answers,
        invalidIds,
        submitting,
        event,
        eventVersion,
        eventMessage,
      ];
}

final class ProfileEditFailure extends ProfileEditState {
  final String message;
  const ProfileEditFailure(this.message);

  @override
  List<Object?> get props => [message];
}
