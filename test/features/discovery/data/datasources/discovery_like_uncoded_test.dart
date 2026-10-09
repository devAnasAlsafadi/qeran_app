import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/discovery/data/datasources/discovery_remote_datasource.dart';
import 'package:qeran/features/discovery/domain/entities/like_outcome.dart';
import 'package:qeran/features/likes/data/error_codes.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class _MockApi extends Mock implements ApiConsumer {}

/// H2: a like is classified by its code only. The Arabic substring fallback
/// is gone — every like error carries its code (Tariq), and release day
/// rewords the very messages it matched (D19). A like error with no code, or
/// a code we don't know, is the generic key — never the server's sentence.
void main() {
  late _MockApi api;
  late DiscoveryRemoteDataSourceImpl ds;

  setUp(() {
    api = _MockApi();
    ds = DiscoveryRemoteDataSourceImpl(apiConsumer: api);
  });

  const quotaSentence = 'لقد استنفدت عدد الإعجابات المسموح به في اشتراكك';

  Matcher generic({String? code}) => throwsA(
    isA<ServerException>()
        .having((e) => e.message, 'message', LocaleKeys.errors_generic)
        .having(
          (e) => e is CodedServerException ? e.errorCode : null,
          'errorCode',
          code,
        ),
  );

  test('a thrown like error with no code is the generic key', () async {
    when(
      () => api.postRaw(any()),
    ).thenThrow(ServerException(message: quotaSentence));

    await expectLater(ds.likeProfile('u1'), generic());
  });

  test('a 200 {status: 0} with no code is the generic key', () async {
    when(
      () => api.postRaw(any()),
    ).thenAnswer((_) async => {'status': 0, 'message': quotaSentence});

    await expectLater(ds.likeProfile('u1'), generic());
  });

  test('an unknown code is the generic key, the code kept', () async {
    when(() => api.postRaw(any())).thenThrow(
      CodedServerException(message: quotaSentence, errorCode: 'NEW_CODE'),
    );

    await expectLater(ds.likeProfile('u1'), generic(code: 'NEW_CODE'));
  });

  test('a known code still classifies, with the server text', () async {
    when(() => api.postRaw(any())).thenThrow(
      CodedServerException(
        message: quotaSentence,
        errorCode: LikesErrorCodes.likesQuotaExceeded,
      ),
    );

    final outcome = await ds.likeProfile('u1');

    expect(
      outcome,
      isA<LikePaywall>().having(
        (o) => o.serverMessage,
        'serverMessage',
        quotaSentence,
      ),
    );
  });
}
