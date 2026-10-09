import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/errors/keyed_server_exception.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/features/discovery/data/datasources/discovery_remote_datasource.dart';
import 'package:qeran/features/legal/data/datasources/legal_remote_datasource.dart';
import 'package:qeran/features/legal/domain/entities/legal_document_type.dart';
import 'package:qeran/features/matchmaker/users/data/datasources/matchmaker_user_actions_remote_datasource.dart';
import 'package:qeran/features/matchmaker/users/data/datasources/matchmaker_user_profile_remote_datasource.dart';
import 'package:qeran/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:qeran/features/questionnaire/data/datasources/questionnaire_remote_datasource.dart';
import 'package:qeran/features/questionnaire/data/error_codes.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/features/subscriptions/data/datasources/subscriptions_remote_datasource.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class _MockApi extends Mock implements ApiConsumer {}

class _MockStorage extends Mock implements StorageService {}

/// Phase 4 B4: the screens that showed a failure's message with `.t()` could
/// show the server's own sentence — often English in the Arabic UI. Each data
/// source behind them now hands up a locale key. One case per call, with the
/// English prose the HTTP layer really puts in the exception.
const _prose = 'The request is invalid.';

CodedServerException _coded([String code = 'SOMETHING_ELSE']) =>
    CodedServerException(message: _prose, errorCode: code, statusCode: 400);

void main() {
  late _MockApi api;

  setUp(() {
    api = _MockApi();
    when(
      () => api.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenThrow(_coded());
    when(
      () => api.getRaw(any(), queryParameters: any(named: 'queryParameters')),
    ).thenThrow(_coded());
    when(() => api.post(any(), body: any(named: 'body'))).thenThrow(_coded());
    when(
      () => api.postRaw(any(), body: any(named: 'body')),
    ).thenThrow(_coded());
  });

  /// Runs [call] and returns the message that escaped.
  Future<String> escaped(Future<void> Function() call) async {
    try {
      await call();
    } on ServerException catch (e) {
      return e.message;
    }
    fail('expected a ServerException');
  }

  void submitFails(String code) => when(
    () => api.post(any(), body: any(named: 'body')),
  ).thenThrow(_coded(code));

  final sites = <String, Future<void> Function()>{
    'legal document (legal screen)': () => LegalRemoteDataSourceImpl(
      apiConsumer: api,
    ).getDocument(LegalDocumentType.privacyPolicy),
    'discovery page (Suggestions)': () =>
        DiscoveryRemoteDataSourceImpl(apiConsumer: api).fetchPage(),
    'plans (packages screen)': () =>
        SubscriptionsRemoteDataSourceImpl(apiConsumer: api).getPlans(),
    'my profile (Profile)': () => ProfileRemoteDataSourceImpl(
      apiConsumer: api,
      secureStorage: _MockStorage(),
    ).getMyProfile(),
    'a profile by id (full profile)': () => ProfileRemoteDataSourceImpl(
      apiConsumer: api,
      secureStorage: _MockStorage(),
    ).getProfileById('u1'),
    'questions (gender step, questionnaire)': () =>
        QuestionnaireRemoteDataSourceImpl(
          apiConsumer: api,
        ).fetchQuestions(gender: Gender.male),
    'the edit form (profile edit)': () =>
        QuestionnaireRemoteDataSourceImpl(apiConsumer: api).fetchEditForm(),
    'submit answers (oath)': () => QuestionnaireRemoteDataSourceImpl(
      apiConsumer: api,
    ).submitAnswers(answers: const []),
    'her member profile': () => MatchmakerUserProfileRemoteDataSourceImpl(
      apiConsumer: api,
    ).getUserProfile('u1'),
    'her approve / reject / request-image': () =>
        MatchmakerUserActionsRemoteDataSourceImpl(
          apiConsumer: api,
        ).approve('u1'),
  };

  for (final MapEntry(key: name, value: call) in sites.entries) {
    test('$name: a key, never the server sentence', () async {
      expect(await escaped(call), LocaleKeys.errors_generic);
    });
  }

  group('the oath\'s submit keeps its own texts', () {
    Future<String> submit() => escaped(
      () => QuestionnaireRemoteDataSourceImpl(
        apiConsumer: api,
      ).submitAnswers(answers: const []),
    );

    test('under 18', () async {
      submitFails(QuestionnaireErrorCodes.underageNotAllowed);
      expect(await submit(), LocaleKeys.errors_underage);
    });

    test('a malformed submission (its prose is English)', () async {
      submitFails(QuestionnaireErrorCodes.validationError);
      expect(await submit(), LocaleKeys.errors_bad_request);
    });
  });

  group('keyedServerException', () {
    test('a coded failure keeps its code, status and data', () {
      final e = keyedServerException(
        CodedServerException(
          message: _prose,
          errorCode: 'X',
          statusCode: 409,
          data: const {'a': 1},
        ),
      );
      expect(e, isA<CodedServerException>());
      e as CodedServerException;
      expect(
        (e.message, e.errorCode, e.statusCode, e.data),
        (LocaleKeys.errors_generic, 'X', 409, const {'a': 1}),
      );
    });

    test('a message that is already a key stays', () {
      final e = keyedServerException(
        ServerException(message: LocaleKeys.errors_timeout),
      );
      expect(e.message, LocaleKeys.errors_timeout);
    });
  });
}
