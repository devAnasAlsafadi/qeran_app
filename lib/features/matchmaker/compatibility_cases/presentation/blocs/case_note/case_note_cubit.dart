import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../../data/case_note_error_codes.dart';
import '../../../domain/usecases/delete_case_note_usecase.dart';
import '../../../domain/usecases/get_case_note_usecase.dart';
import '../../../domain/usecases/save_case_note_usecase.dart';
import 'case_note_state.dart';

/// Drives the notes sheet for one case ([caseId]). Created per sheet (factory).
/// [load] runs the initial GET; [save] / [delete] mutate behind a single
/// in-flight slot and publish a one-shot [CaseNoteOutcome] (with a
/// [CaseNoteErrorKind] derived from the backend errorCode) the sheet turns
/// into inline / toast / pop. Holds no locale strings — the sheet maps the
/// error kind to copy.
class CaseNoteCubit extends Cubit<CaseNoteState> {
  final GetCaseNoteUseCase _getNote;
  final SaveCaseNoteUseCase _saveNote;
  final DeleteCaseNoteUseCase _deleteNote;
  final int caseId;

  /// Max content length AFTER trim — mirrors the backend rule.
  static const int maxLength = 2000;

  CaseNoteCubit({
    required this.caseId,
    required GetCaseNoteUseCase getNote,
    required SaveCaseNoteUseCase saveNote,
    required DeleteCaseNoteUseCase deleteNote,
  })  : _getNote = getNote,
        _saveNote = saveNote,
        _deleteNote = deleteNote,
        super(const CaseNoteState());

  Future<void> load() async {
    emit(state.copyWith(
      load: CaseNoteLoad.loading,
      clearLoadError: true,
    ));
    final result = await _getNote(caseId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        load: CaseNoteLoad.error,
        loadErrorMessage: failure.message,
      )),
      (note) => emit(state.copyWith(
        load: CaseNoteLoad.ready,
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
      _emitFailure(CaseNoteErrorKind.validation, null);
      return;
    }
    emit(state.copyWith(
      inFlight: CaseNoteAction.save,
      clearOutcomeMessage: true,
    ));
    final result = await _saveNote(caseId: caseId, content: content);
    if (isClosed) return;
    result.fold(
      (failure) => _emitFailure(_classify(failure), failure.message),
      (note) => emit(state.copyWith(
        clearInFlight: true,
        note: note,
        outcome: CaseNoteOutcome.saveSuccess,
        errorKind: CaseNoteErrorKind.none,
        eventVersion: state.eventVersion + 1,
      )),
    );
  }

  Future<void> delete() async {
    if (state.isBusy) return;
    emit(state.copyWith(
      inFlight: CaseNoteAction.delete,
      clearOutcomeMessage: true,
    ));
    final result = await _deleteNote(caseId);
    if (isClosed) return;
    result.fold(
      (failure) => _emitFailure(_classify(failure), failure.message),
      (_) => emit(state.copyWith(
        clearInFlight: true,
        clearNote: true,
        outcome: CaseNoteOutcome.deleteSuccess,
        errorKind: CaseNoteErrorKind.none,
        eventVersion: state.eventVersion + 1,
      )),
    );
  }

  void _emitFailure(CaseNoteErrorKind kind, String? message) {
    AppLogger.warning(
      'MATCHMAKER — case note action failed kind=${kind.name}',
      tag: 'MATCHMAKER',
    );
    emit(state.copyWith(
      clearInFlight: true,
      outcome: CaseNoteOutcome.failure,
      errorKind: kind,
      outcomeMessage: message,
      eventVersion: state.eventVersion + 1,
    ));
  }

  CaseNoteErrorKind _classify(Failure failure) {
    if (failure is CodedServerFailure) {
      switch (failure.errorCode) {
        case CaseNoteErrorCodes.validationError:
          return CaseNoteErrorKind.validation;
        case CaseNoteErrorCodes.unauthorized:
          return CaseNoteErrorKind.unauthorized;
        case CaseNoteErrorCodes.caseNotFound:
          return CaseNoteErrorKind.caseNotFound;
        case CaseNoteErrorCodes.notInvolvedInCase:
          return CaseNoteErrorKind.notInvolved;
      }
    }
    return CaseNoteErrorKind.generic;
  }
}
