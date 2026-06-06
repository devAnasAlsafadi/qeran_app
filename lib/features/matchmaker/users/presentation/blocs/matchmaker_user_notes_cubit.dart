import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../data/notes_error_codes.dart';
import '../../domain/usecases/delete_user_note_usecase.dart';
import '../../domain/usecases/get_user_note_usecase.dart';
import '../../domain/usecases/save_user_note_usecase.dart';
import 'matchmaker_user_notes_state.dart';

/// Drives the notes sheet for one user ([userId]). Created per sheet (factory).
/// [load] runs the initial GET; [save] / [delete] mutate behind a single
/// in-flight slot and publish a one-shot [MatchmakerNotesOutcome] (with a
/// [MatchmakerNotesErrorKind] derived from the backend errorCode) the sheet
/// turns into inline / toast / pop.
class MatchmakerUserNotesCubit extends Cubit<MatchmakerUserNotesState> {
  final GetUserNoteUseCase _getNote;
  final SaveUserNoteUseCase _saveNote;
  final DeleteUserNoteUseCase _deleteNote;
  final String userId;

  /// Max content length AFTER trim — mirrors the backend rule.
  static const int maxLength = 2000;

  MatchmakerUserNotesCubit({
    required this.userId,
    required GetUserNoteUseCase getNote,
    required SaveUserNoteUseCase saveNote,
    required DeleteUserNoteUseCase deleteNote,
  })  : _getNote = getNote,
        _saveNote = saveNote,
        _deleteNote = deleteNote,
        super(const MatchmakerUserNotesState());

  Future<void> load() async {
    emit(state.copyWith(
      load: MatchmakerNotesLoad.loading,
      clearLoadError: true,
    ));
    final result = await _getNote(userId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        load: MatchmakerNotesLoad.error,
        loadErrorMessage: failure.message,
      )),
      (note) => emit(state.copyWith(
        load: MatchmakerNotesLoad.ready,
        note: note,
        clearNote: note == null,
      )),
    );
  }

  Future<void> save(String raw) async {
    if (state.isBusy) return;
    final content = raw.trim();
    // Backstop — the UI disables Save when invalid, so this rarely fires.
    if (content.isEmpty || content.length > maxLength) {
      _emitFailure(MatchmakerNotesErrorKind.validation, null);
      return;
    }
    emit(state.copyWith(
      inFlight: MatchmakerNotesAction.save,
      clearOutcomeMessage: true,
    ));
    final result = await _saveNote(userId: userId, content: content);
    if (isClosed) return;
    result.fold(
      (failure) => _emitFailure(_classify(failure), failure.message),
      (note) => emit(state.copyWith(
        clearInFlight: true,
        note: note,
        outcome: MatchmakerNotesOutcome.saveSuccess,
        errorKind: MatchmakerNotesErrorKind.none,
        eventVersion: state.eventVersion + 1,
      )),
    );
  }

  Future<void> delete() async {
    if (state.isBusy) return;
    emit(state.copyWith(
      inFlight: MatchmakerNotesAction.delete,
      clearOutcomeMessage: true,
    ));
    final result = await _deleteNote(userId);
    if (isClosed) return;
    result.fold(
      (failure) => _emitFailure(_classify(failure), failure.message),
      (_) => emit(state.copyWith(
        clearInFlight: true,
        clearNote: true,
        outcome: MatchmakerNotesOutcome.deleteSuccess,
        errorKind: MatchmakerNotesErrorKind.none,
        eventVersion: state.eventVersion + 1,
      )),
    );
  }

  void _emitFailure(MatchmakerNotesErrorKind kind, String? message) {
    AppLogger.warning(
      'MATCHMAKER — note action failed kind=${kind.name}',
      tag: 'MATCHMAKER',
    );
    emit(state.copyWith(
      clearInFlight: true,
      outcome: MatchmakerNotesOutcome.failure,
      errorKind: kind,
      outcomeMessage: message,
      eventVersion: state.eventVersion + 1,
    ));
  }

  MatchmakerNotesErrorKind _classify(Failure failure) {
    if (failure is CodedServerFailure) {
      switch (failure.errorCode) {
        case MatchmakerNotesErrorCodes.validationError:
          return MatchmakerNotesErrorKind.validation;
        case MatchmakerNotesErrorCodes.unauthorized:
          return MatchmakerNotesErrorKind.unauthorized;
        case MatchmakerNotesErrorCodes.userNotFound:
          return MatchmakerNotesErrorKind.userNotFound;
      }
    }
    return MatchmakerNotesErrorKind.generic;
  }
}
