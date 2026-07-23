import 'package:bloc/bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/utils/log_masker.dart';

class SimpleBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    AppLogger.info(
      LogMasker.secrets('Event: ${bloc.runtimeType}, $event'),
      tag: 'BLoC',
    );
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    AppLogger.debug(
      LogMasker.secrets('State Change: ${bloc.runtimeType}, $change'),
      tag: 'BLoC',
    );
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    AppLogger.debug(
      LogMasker.secrets('Transition: ${bloc.runtimeType}, $transition'),
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
