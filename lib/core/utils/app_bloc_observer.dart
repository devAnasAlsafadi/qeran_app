import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:qeran/core/app_logger.dart';

/// Installs [SimpleBlocObserver] in debug builds only. In a release build it
/// would still run on every event and state change, building strings for
/// logs [AppLogger] then drops (cleanup audit `19`, run 11).
void installBlocObserver({bool debug = kDebugMode}) {
  if (debug) Bloc.observer = SimpleBlocObserver();
}

/// Logs which bloc moved and between which state TYPES, never an event's or
/// a state's contents: those carry names, emails, phone numbers, OTPs and
/// tokens (cleanup audit `19`, run 11).
class SimpleBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    AppLogger.info(
      'Event: ${bloc.runtimeType}, ${event.runtimeType}',
      tag: 'BLoC',
    );
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    AppLogger.debug(
      'State Change: ${bloc.runtimeType}, '
      '${change.currentState.runtimeType} → ${change.nextState.runtimeType}',
      tag: 'BLoC',
    );
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    AppLogger.debug(
      'Transition: ${bloc.runtimeType}, ${transition.event.runtimeType}: '
      '${transition.currentState.runtimeType} → '
      '${transition.nextState.runtimeType}',
      tag: 'BLoC',
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    AppLogger.error(
      'Error in ${bloc.runtimeType}',
      error: error,
      stack: stackTrace,
      tag: 'BLoC',
    );
    super.onError(bloc, error, stackTrace);
  }
}
