import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/utils/app_bloc_observer.dart';

class _Untouched extends BlocObserver {}

/// The bloc observer runs in debug builds only: a release build never
/// installs it, so it neither runs nor logs (cleanup audit `19`, run 11).
void main() {
  late BlocObserver original;
  setUp(() => original = Bloc.observer);
  tearDown(() => Bloc.observer = original);

  test('release: nothing installed', () {
    final untouched = _Untouched();
    Bloc.observer = untouched;
    installBlocObserver(debug: false);
    expect(Bloc.observer, same(untouched));
  });

  test('debug: the logging observer', () {
    Bloc.observer = _Untouched();
    installBlocObserver(debug: true);
    expect(Bloc.observer, isA<SimpleBlocObserver>());
  });
}
