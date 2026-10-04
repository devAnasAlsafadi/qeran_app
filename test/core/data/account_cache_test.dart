import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/data/account_cache.dart';
import 'package:qeran/core/errors/errors.dart';

typedef _Answer = Either<Failure, String>;

/// A value read once per account: the edit form's answers, the plans, the
/// Community limits.
void main() {
  late AccountCache<String> cache;
  late int reads;

  setUp(() {
    cache = AccountCache();
    reads = 0;
  });

  Future<_Answer> read(String value) async {
    reads++;
    return Right(value);
  }

  test('read once, then served from memory', () async {
    await cache.get(() => read('A'));

    expect(await cache.get(() => read('B')), const Right<Failure, String>('A'));
    expect(reads, 1);
  });

  test('callers asking while it loads share the one request', () async {
    final answer = Completer<_Answer>();
    var requests = 0;
    Future<_Answer> slow() {
      requests++;
      return answer.future;
    }

    final first = cache.get(slow);
    final second = cache.get(slow);
    answer.complete(const Right('A'));

    expect(await first, const Right<Failure, String>('A'));
    expect(await second, const Right<Failure, String>('A'));
    expect(requests, 1);
  });

  test('a failure is not kept: the next caller reads again', () async {
    await cache.get(() async => const Left(ServerFailure(message: 'down')));

    expect(await cache.get(() => read('A')), const Right<Failure, String>('A'));
  });

  test('forgotten: the next caller reads again', () async {
    await cache.get(() => read('A'));

    cache.forget();

    expect(await cache.get(() => read('B')), const Right<Failure, String>('B'));
  });

  test('forgotten while loading: that answer lands nowhere', () async {
    final previous = Completer<_Answer>();
    final stale = cache.get(() => previous.future);

    cache.forget();
    previous.complete(const Right('A'));
    await stale;

    expect(await cache.get(() => read('B')), const Right<Failure, String>('B'));
  });
}
