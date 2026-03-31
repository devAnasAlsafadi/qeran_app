import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/enum/gender.dart';
import '../../domain/entities/question_entity.dart';
import '../../domain/usecases/fetch_questions_usecase.dart';
import 'questionnaire_state.dart';

class QuestionnaireCubit extends Cubit<QuestionnaireState> {
  final FetchQuestionsUseCase _fetchQuestions;
  final SharedPrefService _sharedPrefs;

  /// In-memory answers: questionId → value (String, List of String, DateTime, or int).
  final Map<String, dynamic> _answers = {};
  List<QuestionEntity> _questions = [];
  int _currentIndex = 0;

  QuestionnaireCubit({
    required FetchQuestionsUseCase fetchQuestions,
    required SharedPrefService sharedPrefs,
  })  : _fetchQuestions = fetchQuestions,
        _sharedPrefs = sharedPrefs,
        super(QuestionnaireInitial());

  // ── Fetch ──────────────────────────────────────────────────────

  Future<void> fetchQuestions({required Gender gender}) async {
    emit(QuestionnaireLoading());
    final result = await _fetchQuestions(gender: gender);
    result.fold(
      (failure) => emit(QuestionnaireFailure(failure.message)),
      (questions) => emit(QuestionnaireFetched(questions)),
    );
  }

  // ── Start Flow ─────────────────────────────────────────────────

  /// Called by the FlowScreen when it receives questions via route arguments.
  /// Non-renderable questions (e.g. `select` with empty options) are filtered
  /// out here so that ALL downstream logic (progress, CTA, navigation) works
  /// automatically on the valid subset.
  void startFlow(List<QuestionEntity> questions) {
    final valid = questions.where((q) => q.isRenderable).toList();

    AppLogger.info(
      'Questionnaire received ${questions.length} question(s), '
      '${valid.length} valid/renderable after filtering.',
      tag: 'QUESTIONNAIRE',
    );

    if (valid.isEmpty) {
      AppLogger.info(
        'No renderable questions — completing questionnaire immediately.',
        tag: 'QUESTIONNAIRE',
      );
      _completeQuestionnaire();
      return;
    }

    _questions = valid;
    _answers.clear();
    _currentIndex = 0;
    _emitInProgress();
  }

  // ── Answer ─────────────────────────────────────────────────────

  void answerQuestion(String questionId, dynamic value) {
    _answers[questionId] = value;
    _emitInProgress();
  }

  // ── Navigation ─────────────────────────────────────────────────

  void nextQuestion() {
    final current = _questions[_currentIndex];
    if (!_answers.containsKey(current.questionId)) return;

    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      _emitInProgress();
    } else {
      _completeQuestionnaire();
    }
  }

  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _emitInProgress();
    }
  }

  // ── Completion ─────────────────────────────────────────────────

  Future<void> _completeQuestionnaire() async {
    AppLogger.info(
      'Questionnaire completed — ${_answers.length} answers',
      tag: 'QUESTIONNAIRE',
    );
    await _sharedPrefs.save(StorageKeys.finishedQuestions, true);
    emit(QuestionnaireCompleted());
  }

  // ── Helpers ────────────────────────────────────────────────────

  void _emitInProgress() {
    emit(QuestionnaireInProgress(
      questions: _questions,
      currentIndex: _currentIndex,
      answers: Map.unmodifiable(_answers),
    ));
  }
}
