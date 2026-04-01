import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/enum/gender.dart';
import '../../domain/entities/question_entity.dart';
import '../../domain/usecases/fetch_questions_usecase.dart';
import '../../domain/usecases/submit_answers_usecase.dart';
import 'questionnaire_state.dart';

class QuestionnaireCubit extends Cubit<QuestionnaireState> {
  final FetchQuestionsUseCase _fetchQuestions;
  final SubmitAnswersUseCase _submitAnswersUseCase;
  final SharedPrefService _sharedPrefs;

  /// In-memory answers: questionId → value (String, List of String, DateTime, or int).
  final Map<String, dynamic> _answers = {};
  List<QuestionEntity> _questions = [];
  int _currentIndex = 0;

  QuestionnaireCubit({
    required FetchQuestionsUseCase fetchQuestions,
    required SubmitAnswersUseCase submitAnswersUseCase,
    required SharedPrefService sharedPrefs,
  })  : _fetchQuestions = fetchQuestions,
        _submitAnswersUseCase = submitAnswersUseCase,
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
  Future<void> startFlow(List<QuestionEntity> questions) async {
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

    // Attempt draft restoration
    try {
      final draftJson = await _sharedPrefs.get<String>(StorageKeys.questionnaireDraft);
      if (draftJson != null) {
        final draft = jsonDecode(draftJson) as Map<String, dynamic>;
        final savedAnswers = draft['answers'] as Map<String, dynamic>? ?? {};
        
        // Restore answers with correct type casting if needed
        savedAnswers.forEach((key, value) {
          if (value is String && _isIsoDateString(value)) {
            _answers[key] = DateTime.parse(value);
          } else if (value is List) {
             _answers[key] = List<String>.from(value);
          } else {
             _answers[key] = value;
          }
        });
        
        final savedIndex = draft['currentIndex'] as int? ?? 0;
        _currentIndex = savedIndex.clamp(0, valid.length - 1);
      }
    } catch (e) {
      AppLogger.warning('Draft parsing failed, clearing corrupt draft', tag: 'QUESTIONNAIRE');
      await _sharedPrefs.remove(StorageKeys.questionnaireDraft);
      _answers.clear();
      _currentIndex = 0;
    }

    _emitInProgress();
  }

  bool _isIsoDateString(String s) {
    try {
      if(s.length >= 10 && s.contains('-')){
        DateTime.parse(s);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Answer ─────────────────────────────────────────────────────

  void answerQuestion(String questionId, dynamic value) {
    _answers[questionId] = value;
    _saveDraft();
    _emitInProgress();
  }

  // ── Navigation ─────────────────────────────────────────────────

  void nextQuestion() {
    final current = _questions[_currentIndex];
    if (!_answers.containsKey(current.questionId)) return;

    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      _saveDraft();
      _emitInProgress();
    } else {
      _completeQuestionnaire();
    }
  }

  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _saveDraft();
      _emitInProgress();
    }
  }

  // ── Completion ─────────────────────────────────────────────────

  Future<void> submitAnswers() async {
    emit(QuestionnaireSubmitting());

    final answersPayload = _questions.map((q) {
      final answer = _answers[q.questionId];

      String textAnswer = "";
      List<String> selectedOptions = [];

      switch (q.type) {
        case QuestionType.date:
        case QuestionType.height:
        case QuestionType.weight:
        case QuestionType.text:
          // Input-based questions
          if (answer is DateTime) {
             textAnswer = "${answer.year}-${answer.month.toString().padLeft(2, '0')}-${answer.day.toString().padLeft(2, '0')}";
          } else {
             textAnswer = answer.toString();
          }
          break;
        case QuestionType.checkbox:
        case QuestionType.interests:
          // Multi-select questions
          selectedOptions = List<String>.from(answer ?? []);
          break;
        case QuestionType.select:
        case QuestionType.radio:
          // Single-select questions
          if (answer != null) {
            selectedOptions = [answer.toString()];
          }
          break;
        case QuestionType.unknown:
          break;
      }

      return {
        "questionId": q.questionId,
        "textAnswer": textAnswer,
        "selectedOptions": selectedOptions,
      };
    }).toList();

    final result = await _submitAnswersUseCase(answers: answersPayload);

    result.fold(
      (failure) {
        emit(QuestionnaireSubmissionFailure(failure.message));
        _emitInProgress(); // Re-emit in progress to show UI again
      },
      (success) async {
        await _completeQuestionnaire();
      },
    );
  }

  Future<void> _completeQuestionnaire() async {
    AppLogger.info(
      'Questionnaire completed — ${_answers.length} answers',
      tag: 'QUESTIONNAIRE',
    );
    await _sharedPrefs.remove(StorageKeys.questionnaireDraft);
    await _sharedPrefs.save(StorageKeys.finishedQuestions, true);
    emit(QuestionnaireCompleted());
  }

  // ── Helpers ────────────────────────────────────────────────────

  void _saveDraft() {
    final draft = {
      'currentIndex': _currentIndex,
      'answers': _answers.map((k, v) {
        if (v is DateTime) {
          return MapEntry(k, v.toIso8601String());
        }
        return MapEntry(k, v);
      }),
    };
    _sharedPrefs.save(StorageKeys.questionnaireDraft, jsonEncode(draft));
  }

  void _emitInProgress() {
    emit(QuestionnaireInProgress(
      questions: _questions,
      currentIndex: _currentIndex,
      answers: Map.unmodifiable(_answers),
    ));
  }
}
