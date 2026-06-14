import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/features/questionnaire/domain/entities/question_entity.dart';
import 'package:qeran/features/questionnaire/domain/entities/question_option_entity.dart';
import 'package:qeran/features/questionnaire/domain/usecases/fetch_questions_usecase.dart';
import 'package:qeran/features/questionnaire/presentation/blocs/questionnaire_cubit.dart';
import 'package:qeran/features/questionnaire/presentation/blocs/questionnaire_state.dart';

class _MockFetchQuestions extends Mock implements FetchQuestionsUseCase {}

const _opt = QuestionOptionEntity(id: 'o1', text: 'Option 1');

QuestionEntity _question(
  String id,
  QuestionType type, {
  List<QuestionOptionEntity> options = const [],
}) =>
    QuestionEntity(
      questionId: id,
      text: 'Q $id',
      type: type,
      options: options,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuestionnaireCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    cubit = QuestionnaireCubit(
      fetchQuestions: _MockFetchQuestions(),
      sharedPrefs: SharedPrefService(prefs),
    );
  });

  tearDown(() => cubit.close());

  group('startFlow — defensive filter of unanswerable questions', () {
    test(
        'drops option-type questions with empty options, keeps answerable, '
        'index/progress derive from the filtered list', () async {
      final questions = [
        _question('q1', QuestionType.select, options: [_opt]), // keep
        _question('q2', QuestionType.select), // drop (empty options)
        _question('q3', QuestionType.text), // keep
        _question('q4', QuestionType.checkbox), // drop (empty options)
        _question('q5', QuestionType.radio, options: [_opt]), // keep
        _question('q6', QuestionType.interests), // drop (empty options)
        _question('q7', QuestionType.date), // keep
      ];

      await cubit.startFlow(questions);

      final state = cubit.state;
      expect(state, isA<QuestionnaireInProgress>());
      final inProgress = state as QuestionnaireInProgress;

      // Only the four answerable questions survive, in order.
      expect(
        inProgress.questions.map((q) => q.questionId).toList(),
        ['q1', 'q3', 'q5', 'q7'],
      );
      // Index/progress reflect the filtered length (4), not the original (7).
      expect(inProgress.currentIndex, 0);
      expect(inProgress.isFirst, isTrue);
      expect(inProgress.isLast, isFalse);
      expect(inProgress.progress, 1 / 4);
    });

    test('keeps every answerable question when none are broken', () async {
      final questions = [
        _question('q1', QuestionType.select, options: [_opt]),
        _question('q2', QuestionType.checkbox, options: [_opt]),
        _question('q3', QuestionType.interests, options: [_opt]),
        _question('q4', QuestionType.radio, options: [_opt]),
        _question('q5', QuestionType.text),
        _question('q6', QuestionType.date),
        _question('q7', QuestionType.height),
        _question('q8', QuestionType.weight),
        _question('q9', QuestionType.unknown),
      ];

      await cubit.startFlow(questions);

      final inProgress = cubit.state as QuestionnaireInProgress;
      expect(inProgress.questions.length, 9);
      expect(inProgress.isLast, isFalse);
      expect(inProgress.progress, 1 / 9);
    });

    test(
        'when ALL questions are unanswerable, proceeds to oath with an empty '
        'payload (empty-list path intact)', () async {
      final questions = [
        _question('q1', QuestionType.select), // empty options
        _question('q2', QuestionType.checkbox), // empty options
        _question('q3', QuestionType.interests), // empty options
      ];

      await cubit.startFlow(questions);

      final state = cubit.state;
      expect(state, isA<QuestionnaireReadyForOath>());
      expect((state as QuestionnaireReadyForOath).answersPayload, isEmpty);
    });

    test('a single answerable question is correctly the last one', () async {
      final questions = [
        _question('q1', QuestionType.select), // drop
        _question('q2', QuestionType.text), // keep
      ];

      await cubit.startFlow(questions);

      final inProgress = cubit.state as QuestionnaireInProgress;
      expect(inProgress.questions.map((q) => q.questionId), ['q2']);
      expect(inProgress.isFirst, isTrue);
      expect(inProgress.isLast, isTrue);
      expect(inProgress.progress, 1.0);
    });
  });
}
