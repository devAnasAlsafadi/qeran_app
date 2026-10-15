import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/errors/server_error_classifier.dart';
import 'package:qeran/core/state/paginated_list_cubit_mixin.dart';
import 'package:qeran/core/state/paginated_list_state.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class _Repo with BaseRepository {
  Future<Either<Failure, int>> run(Object error) =>
      executeApiCall<int>(() async => throw error);
}

class _List extends Cubit<PaginatedListState<int>>
    with PaginatedListCubitMixin<int> {
  _List(this.error) : super(const PaginatedListState<int>());
  final Object error;

  @override
  Future<({List<int> items, bool hasMore})> fetchPage(int page) =>
      Future.error(error);
}

Failure _failure(Either<Failure, int> result) =>
    result.fold((f) => f, (_) => throw StateError('expected a failure'));

/// Cleanup audit `19`, run 11: no member reads the server's own sentence. A
/// failure leaving a repository, or a paginated list's error, is a locale key
/// (a data source's errorCode key, a transport key) or «حدث خطأ، حاول مرة
/// أخرى»; its errorCode still travels.
void main() {
  test('keys pass, sentences become errors.generic, empty stays', () {
    expect(keyOrGeneric('errors.timeout'), 'errors.timeout');
    expect(keyOrGeneric(' support.limit_reached '), 'support.limit_reached');
    expect(keyOrGeneric('المستخدم غير موجود'), LocaleKeys.errors_generic);
    expect(keyOrGeneric('Object reference not set'), LocaleKeys.errors_generic);
    expect(keyOrGeneric(''), '');
  });

  test('a repository failure: the sentence goes, the code stays', () async {
    final coded = _failure(
      await _Repo().run(
        CodedServerException(
          message: 'Value cannot be null. (Parameter x)',
          errorCode: 'SUPPORT_TICKETS_LIMIT_REACHED',
        ),
      ),
    );
    expect(coded.message, LocaleKeys.errors_generic);
    expect(
      (coded as CodedServerFailure).errorCode,
      'SUPPORT_TICKETS_LIMIT_REACHED',
    );

    final plain = _failure(
      await _Repo().run(ServerException(message: LocaleKeys.errors_server)),
    );
    expect(plain.message, LocaleKeys.errors_server);

    final auth = _failure(
      await _Repo().run(AuthException(message: 'Unauthorized', reference: 'R')),
    );
    expect(auth.message, LocaleKeys.errors_generic);
    expect((auth as AuthFailure).reference, 'R');
  });

  test('a paginated list error: a key, never the exception text', () async {
    final raw = _List(StateError('Bad state: no element'));
    await raw.loadFirst();
    expect(raw.state.errorMessage, LocaleKeys.errors_generic);

    final keyed = _List(const _Keyed(LocaleKeys.errors_timeout));
    await keyed.loadFirst();
    expect(keyed.state.errorMessage, LocaleKeys.errors_timeout);
  });
}

/// A cubit's fetch exception, which prints its failure's message.
class _Keyed implements Exception {
  const _Keyed(this.message);
  final String message;

  @override
  String toString() => message;
}
