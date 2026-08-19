part of 'photo_manager_cubit.dart';

/// Everything about files the user has picked but not sent: staging them,
/// dropping them, and the validation that decides whether a file may be
/// staged at all. None of it touches the network.

/// How many leading bytes identify a format. Four covers the longest
/// signature we check (PNG); JPEG needs only three.
const int _signatureLength = 4;

/// The only formats the backend accepts (Tariq: jpg / jpeg / png), matched on
/// CONTENT rather than filename.
///
/// A name is not evidence. Android's image_picker re-encodes every pick to
/// JPEG (we pass `imageQuality: 85`, which forces it) but writes the result
/// under the ORIGINAL filename — so a photo picked from an iPhone-synced
/// gallery arrives as `scaled_x.heic` holding perfectly good JPEG bytes.
/// Judging that by its extension refuses a photo the backend would have
/// taken. The reverse is just as wrong: anything can be renamed `.jpg`.
///
/// Matching the bytes is what the server does, so client and server agree on
/// one rule instead of two that drift.
const List<int> _jpegSignature = [0xFF, 0xD8, 0xFF];
const List<int> _pngSignature = [0x89, 0x50, 0x4E, 0x47];

/// The file's first [_signatureLength] bytes, or null when it cannot be read.
///
/// Opened by hand and closed in a `finally` so exactly the signature comes off
/// disk — the file may be megabytes, and none of the rest is needed to know
/// what it is. Synchronous on purpose: every other check in [_validate] is,
/// and the picker calls it from a plain `void` method.
List<int>? _readSignature(File file) {
  RandomAccessFile? handle;
  try {
    handle = file.openSync();
    return handle.readSync(_signatureLength);
  } catch (_) {
    return null;
  } finally {
    try {
      handle?.closeSync();
    } catch (_) {
      // Closing a handle we already failed to read is not worth reporting.
    }
  }
}

bool _hasSupportedSignature(List<int> bytes) =>
    _startsWith(bytes, _jpegSignature) || _startsWith(bytes, _pngSignature);

/// Short-circuits on the first mismatch. A file shorter than the signature
/// (an empty pick, a truncated download) can never match one.
bool _startsWith(List<int> bytes, List<int> signature) {
  if (bytes.length < signature.length) return false;
  for (var i = 0; i < signature.length; i++) {
    if (bytes[i] != signature[i]) return false;
  }
  return true;
}

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
  ///
  /// Ordered cheapest-first, and size before content: an oversized file is
  /// rejected without ever being opened.
  String? _validate(String path) {
    final file = File(path);
    if (!file.existsSync()) return LocaleKeys.auth_photo_validation_not_found;
    final int length;
    try {
      length = file.lengthSync();
    } catch (_) {
      return LocaleKeys.auth_photo_validation_read_error;
    }
    if (length > _maxBytes) return LocaleKeys.auth_photo_validation_size;
    final signature = _readSignature(file);
    // Unreadable is not the same as unsupported — a file we could stat but
    // not open is a device problem, and telling the user to pick a JPG would
    // send them off to fix the wrong thing.
    if (signature == null) return LocaleKeys.auth_photo_validation_read_error;
    if (!_hasSupportedSignature(signature)) {
      return LocaleKeys.profile_photos_validation_type;
    }
    return null;
  }
}
