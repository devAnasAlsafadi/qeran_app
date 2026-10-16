import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/utils/app_bloc_observer.dart';

/// A state and an event carrying what the observer must never print.
class _Signed {
  const _Signed(this.name);
  final String name;

  @override
  String toString() => '_Signed(name: $name, otp: 482913)';
}

class _Submit {
  @override
  String toString() => '_Submit(otp: 482913, name: Layla Example)';
}

class _SessionCubit extends Cubit<Object> {
  _SessionCubit() : super('loading');
}

class _OtpBloc extends Bloc<_Submit, Object> {
  _OtpBloc() : super('idle') {
    on<_Submit>((_, emit) => emit(const _Signed('Layla Example')));
  }
}

/// Debug logs name the bloc and the state types, never their contents: a
/// name or an OTP carries no pattern a masker could find (cleanup audit
/// `19`, run 11).
void main() {
  final lines = <String>[];
  final originalSink = AppLogger.sink;
  late BlocObserver originalObserver;

  setUp(() {
    lines.clear();
    originalObserver = Bloc.observer;
    Bloc.observer = SimpleBlocObserver();
    AppLogger.sink = (message, tag, error, stack) => lines.add(message);
  });
  tearDown(() {
    Bloc.observer = originalObserver;
    AppLogger.sink = originalSink;
  });

  test('a state change logs types only', () async {
    final cubit = _SessionCubit();
    cubit.emit(const _Signed('Layla Example'));
    await cubit.close();

    expect(lines.join('\n'), contains('_SessionCubit'));
    expect(lines.join('\n'), contains('_Signed'));
    expect(lines.join('\n'), isNot(contains('Layla')));
    expect(lines.join('\n'), isNot(contains('482913')));
  });

  test('an event and its transition log types only', () async {
    final bloc = _OtpBloc()..add(_Submit());
    await Future<void>.delayed(Duration.zero);
    await bloc.close();

    expect(lines.join('\n'), contains('_Submit'));
    expect(lines.join('\n'), isNot(contains('Layla')));
    expect(lines.join('\n'), isNot(contains('482913')));
  });

  // A code is six digits: too short for the masker to recognise, so no
  // string may interpolate it (the WhatsApp screen logs its length only).
  test('no string in lib/ interpolates an OTP', () {
    final interpolated = RegExp(r'\$\{?otp\b');
    final found = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (interpolated.hasMatch(lines[i])) found.add('${file.path}:${i + 1}');
      }
    }
    expect(found, isEmpty);
  });
}
