part of 'photo_manager_cubit.dart';

/// Everything about files the user has picked but not sent: staging them,
/// dropping them, and the validation that decides whether a file may be
/// staged at all. None of it touches the network.

/// The only formats the backend accepts (Tariq: jpg / jpeg / png).
const Set<String> _allowedExtensions = {'.jpg', '.jpeg', '.png'};

/// Client-side size ceiling, matched to the server's own limit (Tariq: 5 MB
/// per file). Kept as a pre-check rather than left to the backend so an
/// oversized pick is refused before megabytes go up the wire — the server
/// still has the last word via `IMAGE_TOO_LARGE`.
const int _maxBytes = 5 * 1024 * 1024;

extension PhotoManagerStaging on PhotoManagerCubit {
  /// Stages a picked file locally. Nothing is sent until [upload] runs.
  void addImage(String path) {
    if (state.isBusy) return;
    if (!state.canAddMore) {
      _event(PhotoManagerEvent.maxReached);
      return;
    }
    final validation = _validate(path);
    if (validation != null) {
      _event(PhotoManagerEvent.validationFailure, errorMessage: validation);
      return;
    }
    // The very first photo of an empty profile is the main one by default,
    // matching what registration has always done.
    final isFirstEverPhoto = state.totalCount == 0;
    emit(
      state.copyWith(
        stagedPaths: [...state.stagedPaths, path],
        stagedMainPath: isFirstEverPhoto ? path : null,
        clearError: true,
      ),
    );
  }

  /// Drops a staged file. No request — it was never uploaded.
  void removeStaged(String path) {
    if (state.isBusy) return;
    final remaining = [...state.stagedPaths]..remove(path);
    final losingMain = state.stagedMainPath == path;
    emit(
      state.copyWith(
        stagedPaths: remaining,
        // Promote the next staged photo so the user is never left with a
        // staged-only set and no main.
        stagedMainPath: losingMain && remaining.isNotEmpty && !_serverHasMain
            ? remaining.first
            : null,
        clearStagedMain: losingMain && (remaining.isEmpty || _serverHasMain),
      ),
    );
  }

  bool get _serverHasMain => state.serverImages.any((i) => i.isProfile);

  /// Returns a locale key when the file is unusable, or null when it passes.
  String? _validate(String path) {
    final file = File(path);
    if (!file.existsSync()) return LocaleKeys.auth_photo_validation_not_found;
    final extension = path.contains('.')
        ? path.substring(path.lastIndexOf('.')).toLowerCase()
        : '';
    if (!_allowedExtensions.contains(extension)) {
      return LocaleKeys.auth_photo_validation_type;
    }
    try {
      if (file.lengthSync() > _maxBytes) {
        return LocaleKeys.auth_photo_validation_size;
      }
    } catch (_) {
      return LocaleKeys.auth_photo_validation_read_error;
    }
    return null;
  }
}
