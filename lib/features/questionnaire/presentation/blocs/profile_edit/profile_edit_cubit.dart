import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/core/app_logger.dart';

import '../../../domain/entities/editable_category.dart';
import '../../../domain/entities/editable_question.dart';
import '../../../domain/entities/question_entity.dart';
import '../../../domain/usecases/get_edit_form_usecase.dart';
import '../../../domain/usecases/submit_answers_usecase.dart';
import 'profile_edit_state.dart';

/// Drives the profile-edit form: loads `GET /api/questions/edit-form`, seeds a
/// working answer map, validates required fields client-side, and on save
/// sends EVERY question to `submit` (the server replaces ALL answers, so the
/// full set must be replayed even if only one field changed).
class ProfileEditCubit extends Cubit<ProfileEditState> with SafeEmit<ProfileEditState> {
  final GetEditFormUseCase _getEditForm;
  final SubmitAnswersUseCase _submit;

  ProfileEditCubit({
    required GetEditFormUseCase getEditForm,
    required SubmitAnswersUseCase submit,
  })  : _getEditForm = getEditForm,
        _submit = submit,
        super(const ProfileEditInitial());

  List<EditableCategory> _categories = const [];

  /// Working answers keyed by questionId. Mutated as the user edits; replayed
  /// in full on save.
  final Map<String, dynamic> _answers = {};

  Future<void> load() async {
    emit(const ProfileEditLoading());
    final result = await _getEditForm();
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'Edit form load failed message="${failure.message}"',
          tag: 'PROFILE_EDIT',
        );
        emit(ProfileEditFailure(failure.message));
      },
      (categories) {
        _categories = categories;
        _seedAnswers(categories);
        emit(ProfileEditLoaded(
          categories: categories,
          answers: Map.of(_answers),
        ));
      },
    );
  }

  Future<void> refresh() => load();

  /// Records an edit to one question and clears any pending required-error on
  /// it. Emits a fresh [ProfileEditLoaded] so the field's BlocSelector updates.
  void updateAnswer(String questionId, dynamic value) {
    final current = state;
    if (current is! ProfileEditLoaded) return;
    _answers[questionId] = value;
    final invalid = current.invalidIds.contains(questionId)
        ? ({...current.invalidIds}..remove(questionId))
        : current.invalidIds;
    emit(current.copyWith(answers: Map.of(_answers), invalidIds: invalid));
  }

  /// Validates required fields, then replays every question to `submit`.
  Future<void> save() async {
    final current = state;
    if (current is! ProfileEditLoaded || current.submitting) return;

    final invalid = _findInvalid();
    if (invalid.isNotEmpty) {
      emit(current.copyWith(
        invalidIds: invalid,
        event: ProfileEditEvent.validationError,
        eventVersion: current.eventVersion + 1,
        eventMessage: null,
      ));
      return;
    }

    emit(current.copyWith(submitting: true, invalidIds: const {}));
    final result = await _submit(answers: _buildPayload());
    if (isClosed) return;
    final loaded = state;
    if (loaded is! ProfileEditLoaded) return;
    result.fold(
      (failure) => emit(loaded.copyWith(
        submitting: false,
        event: ProfileEditEvent.saveFailure,
        eventVersion: loaded.eventVersion + 1,
        eventMessage: failure.message,
      )),
      (success) => emit(loaded.copyWith(
        submitting: false,
        event: ProfileEditEvent.saveSuccess,
        eventVersion: loaded.eventVersion + 1,
        eventMessage: success.message,
      )),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────

  void _seedAnswers(List<EditableCategory> categories) {
    _answers.clear();
    for (final category in categories) {
      for (final question in category.questions) {
        _answers[question.questionId] = _seedValue(question);
      }
    }
  }

  dynamic _seedValue(EditableQuestion q) {
    switch (q.type) {
      case QuestionType.select:
      case QuestionType.radio:
        return q.selectedOptionIds.isNotEmpty
            ? q.selectedOptionIds.first
            : null;
      case QuestionType.checkbox:
      case QuestionType.interests:
        return List<String>.from(q.selectedOptionIds);
      case QuestionType.date:
        final raw = q.textAnswer;
        return (raw == null || raw.isEmpty) ? null : DateTime.tryParse(raw);
      case QuestionType.height:
      case QuestionType.weight:
        return int.tryParse(q.textAnswer ?? '');
      case QuestionType.text:
      case QuestionType.unknown:
        return q.textAnswer;
    }
  }

  Set<String> _findInvalid() {
    final invalid = <String>{};
    for (final category in _categories) {
      for (final q in category.questions) {
        if (q.isRequired && _isEmpty(q.type, _answers[q.questionId])) {
          invalid.add(q.questionId);
        }
      }
    }
    return invalid;
  }

  bool _isEmpty(QuestionType type, dynamic value) {
    switch (type) {
      case QuestionType.checkbox:
      case QuestionType.interests:
        return value is! List || value.isEmpty;
      case QuestionType.date:
        return value is! DateTime;
      case QuestionType.height:
      case QuestionType.weight:
        return value is! int;
      case QuestionType.select:
      case QuestionType.radio:
      case QuestionType.text:
      case QuestionType.unknown:
        return value == null || (value as String).trim().isEmpty;
    }
  }

  List<Map<String, dynamic>> _buildPayload() {
    final payload = <Map<String, dynamic>>[];
    for (final category in _categories) {
      for (final q in category.questions) {
        final answer = _answers[q.questionId];
        String textAnswer = '';
        List<String> selectedOptions = const [];
        switch (q.type) {
          case QuestionType.date:
            if (answer is DateTime) textAnswer = _formatDate(answer);
            break;
          case QuestionType.height:
          case QuestionType.weight:
            if (answer is int) textAnswer = answer.toString();
            break;
          case QuestionType.text:
          case QuestionType.unknown:
            if (answer is String) textAnswer = answer;
            break;
          case QuestionType.checkbox:
          case QuestionType.interests:
            selectedOptions =
                answer is List ? List<String>.from(answer) : const [];
            break;
          case QuestionType.select:
          case QuestionType.radio:
            if (answer != null) selectedOptions = [answer.toString()];
            break;
        }
        payload.add({
          'questionId': q.questionId,
          'selectedOptions': selectedOptions,
          'textAnswer': textAnswer,
        });
      }
    }
    return payload;
  }

  String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}
