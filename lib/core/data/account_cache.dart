import 'package:dartz/dartz.dart';

import '../errors/errors.dart';

/// One value fetched once and then served from memory until the account
/// changes. Callers that ask while it's being fetched share that request; a
/// failure isn't kept, so the next caller tries again.
///
/// [forget] drops the value and any request still in flight: that request's
/// answer belongs to the previous account, so it lands nowhere.
class AccountCache<T> {
  T? _value;
  Future<Either<Failure, T>>? _inflight;
  int _generation = 0;

  Future<Either<Failure, T>> get(Future<Either<Failure, T>> Function() fetch) {
    final cached = _value;
    if (cached != null) return Future.value(Right(cached));
    final existing = _inflight;
    if (existing != null) return existing;

    final generation = _generation;
    final task = fetch().then((result) {
      if (generation == _generation) {
        result.fold((_) {}, (value) => _value = value);
      }
      return result;
    });
    _inflight = task;
    task.whenComplete(() {
      if (identical(_inflight, task)) _inflight = null;
    });
    return task;
  }

  void forget() {
    _generation++;
    _value = null;
    _inflight = null;
  }
}
