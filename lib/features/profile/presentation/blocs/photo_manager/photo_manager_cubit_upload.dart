part of 'photo_manager_cubit.dart';

/// The upload half of [PhotoManagerCubit], split out purely for size: the
/// batch upload carries its own ordering rules, its own promotion round-trip
/// and its own failure semantics, none of which the per-photo mutations
/// (delete, set-main) need to reason about.
///
/// An extension rather than a second class, so nothing about the cubit's
/// public shape or its registration changes. Being a `part` keeps it in the
/// same library, which is what lets it reach the private use cases.
extension PhotoManagerUpload on PhotoManagerCubit {
  /// Uploads every staged file in one multipart request, main photo first.
  ///
  /// No explicit promotion afterwards: a staged main can only exist on a
  /// profile with NO server photos (every site that sets `stagedMainPath` is
  /// guarded that way), and for an empty profile the backend already takes
  /// multipart file 0 as the main one — which `_mainFirst` guarantees is the
  /// chosen photo. Once server photos DO exist, promoting a staged tile goes
  /// through [uploadAndSetMain] instead and never reaches here.
  ///
  /// On failure the staged files are deliberately kept so the user can
  /// retry without re-picking them.
  Future<void> upload() async {
    if (state.isBusy || !state.hasStaged) return;

    for (final path in state.stagedPaths) {
      final error = _validate(path);
      if (error != null) {
        _event(PhotoManagerEvent.validationFailure, errorMessage: error);
        return;
      }
    }

    final ordered = _mainFirst(state.stagedPaths, state.stagedMainPath);

    emit(
      state.copyWith(
        inFlight: PhotoManagerAction.upload,
        clearError: true,
      ),
    );

    final result = await _addImages(
      ordered.map(File.new).toList(growable: false),
    );
    if (isClosed) return;

    String? failure;
    result.fold<void>((f) => failure = f.message, (_) {});
    if (failure != null) {
      AppLogger.error('Photo upload failed: $failure', tag: 'PHOTO_MANAGER');
      emit(
        state.copyWith(
          clearInFlight: true,
          event: PhotoManagerEvent.actionFailure,
          eventVersion: state.eventVersion + 1,
          errorMessage: failure,
        ),
      );
      return;
    }

    await _sharedPrefs.save(StorageKeys.uploadedPhotos, true);

    // Registration moves on to the app; profile edit stays put and just
    // confirms the photos are pending review.
    await _reloadAfterMutation(
      state.mode == PhotoManagerMode.onboarding
          ? PhotoManagerEvent.finished
          : PhotoManagerEvent.uploaded,
      clearStaged: true,
    );
  }

  /// Returns [paths] with [main] moved to the front. The backend treats
  /// the first file in the multipart body as the profile photo.
  List<String> _mainFirst(List<String> paths, String? main) {
    if (main == null || paths.isEmpty || paths.first == main) {
      return List.of(paths);
    }
    return [main, ...paths.where((p) => p != main)];
  }

  /// Uploads ONE staged photo and promotes it — a single action from the
  /// user's side, two requests underneath.
  ///
  /// Separate from [upload] because the batch cannot express "this one, now":
  /// it sends everything staged and lets the backend treat file 0 as main.
  /// Here the id comes straight back from the POST (the response carries
  /// exactly the images this request created), so the promotion is explicit.
  /// [upload] never runs on this path, so its promotion cannot also fire —
  /// exactly one set-main per tap.
  Future<void> uploadAndSetMain(StagedPhotoSlot slot) async {
    if (state.isBusy) return;
    final path = slot.path;
    final invalid = _validate(path);
    if (invalid != null) {
      _event(PhotoManagerEvent.validationFailure, errorMessage: invalid);
      return;
    }
    _beginMutation(PhotoManagerAction.promoteStaged, path);
    try {
      final uploaded = await _addImages([File(path)]);
      if (isClosed) return;
      String? uploadError;
      var created = const <OwnerImage>[];
      uploaded.fold((f) => uploadError = f.message, (images) => created = images);
      final failed = uploadError;
      if (failed != null) {
        // The file never left the device — it stays staged so a retry costs
        // the user nothing.
        AppLogger.error('Promote-staged upload failed: $failed',
            tag: 'PHOTO_MANAGER');
        _failMutation(failed);
        return;
      }
      await _sharedPrefs.save(StorageKeys.uploadedPhotos, true);
      if (isClosed) return;
      await _promoteUploaded(path, created);
    } finally {
      _endMutation(path);
    }
  }

  /// Second half of [uploadAndSetMain]. The photo is on the server by now, so
  /// the staged copy is dropped whichever way the promotion goes.
  Future<void> _promoteUploaded(String path, List<OwnerImage> created) async {
    String? error;
    if (created.isEmpty) {
      // One file in, so exactly one image should come back. An empty response
      // means we have nothing to promote and cannot silently claim success.
      error = LocaleKeys.errors_invalid_server_response;
    } else {
      final promoted = await _setMain(created.first.id);
      if (isClosed) return;
      promoted.fold((f) => error = f.message, (_) {});
    }
    await _reloadAfterPromotion(path, error);
  }

  /// Drops [path] from staging and refreshes from the server.
  ///
  /// A non-null [error] means the upload landed but the promotion did not.
  /// Nothing is rolled back: the photo genuinely exists now, it simply is not
  /// main, and the user can promote it from its server tile. Reporting the
  /// failure over FRESH state is what keeps that tile there to tap.
  Future<void> _reloadAfterPromotion(String path, String? error) async {
    final refreshed = await _getImages();
    if (isClosed) return;
    final remaining = [...state.stagedPaths]..remove(path);
    final failed = error != null;
    refreshed.fold(
      (f) => emit(
        state.copyWith(
          clearInFlight: true,
          stagedPaths: remaining,
          event: PhotoManagerEvent.actionFailure,
          eventVersion: state.eventVersion + 1,
          errorMessage: error ?? f.message,
        ),
      ),
      (images) => emit(
        state.copyWith(
          status: PhotoManagerStatus.loaded,
          serverImages: images,
          stagedPaths: remaining,
          clearStagedMain: true,
          clearInFlight: true,
          event: failed
              ? PhotoManagerEvent.actionFailure
              : PhotoManagerEvent.mainChanged,
          eventVersion: state.eventVersion + 1,
          errorMessage: error,
          clearError: !failed,
        ),
      ),
    );
  }
}
