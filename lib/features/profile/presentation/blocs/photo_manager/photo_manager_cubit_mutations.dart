part of 'photo_manager_cubit.dart';

/// The two per-photo server mutations — delete and set-main — plus the
/// lock/loading bookkeeping they share.
///
/// Both follow the same contract: claim the screen and flag ONE photo, run
/// the request, hand the outcome to [PhotoManagerCubit._finishMutation], and
/// release the photo in a `finally` no matter what happened.
extension PhotoManagerMutations on PhotoManagerCubit {
  /// Deletes a photo that already lives on the server.
  Future<void> deleteServerImage(String imageId) async {
    if (state.isBusy) return;
    _beginMutation(PhotoManagerAction.delete, imageId);
    try {
      final result = await _deleteImage(imageId);
      await _finishMutation(result, PhotoManagerEvent.deleted);
    } finally {
      _endMutation(imageId);
    }
  }

  /// Promotes a slot to main. A server photo goes through the API; a
  /// staged photo is only recorded locally and takes effect after upload.
  Future<void> setMain(PhotoSlot slot) async {
    if (state.isBusy) return;
    switch (slot) {
      // Nothing is on the server yet (registration), so there is no rival
      // main to diverge from: record the choice and let the batch upload
      // honour it via `_mainFirst`. Once server photos DO exist, a local-only
      // flag would leave two photos wearing the Main badge — one real, one
      // aspirational — so the tap becomes a real upload-and-promote instead.
      case StagedPhotoSlot(:final path) when state.serverImages.isEmpty:
        emit(state.copyWith(stagedMainPath: path, clearError: true));
        _event(PhotoManagerEvent.mainChanged);
      case StagedPhotoSlot():
        await uploadAndSetMain(slot);
      case ServerPhotoSlot(:final id):
        _beginMutation(
          PhotoManagerAction.setMain,
          id,
          clearStagedMain: true,
        );
        try {
          final result = await _setMain(id);
          await _finishMutation(result, PhotoManagerEvent.mainChanged);
        } finally {
          _endMutation(id);
        }
    }
  }

  /// Claims the screen-wide lock AND flags [photoId] as the one photo this
  /// mutation touches, so only its tile can render a loader.
  ///
  /// One emit, not two: the lock and the id are the same decision, and
  /// splitting them would rebuild the grid twice for a single tap.
  void _beginMutation(
    PhotoManagerAction action,
    String photoId, {
    bool clearStagedMain = false,
  }) {
    emit(
      state.copyWith(
        inFlight: action,
        inFlightPhotoIds: {...state.inFlightPhotoIds, photoId},
        clearError: true,
        clearStagedMain: clearStagedMain,
      ),
    );
  }

  /// Releases [photoId]. Always called from a `finally`, so a throw anywhere
  /// on the network path cannot leave a tile spinning forever. The lock
  /// itself is released separately, by the emit that reports the outcome.
  void _endMutation(String photoId) {
    if (!state.inFlightPhotoIds.contains(photoId)) return;
    emit(
      state.copyWith(
        inFlightPhotoIds: {...state.inFlightPhotoIds}..remove(photoId),
      ),
    );
  }

  /// Ends a mutation that never got far enough to change server state.
  void _failMutation(String message) {
    emit(
      state.copyWith(
        clearInFlight: true,
        event: PhotoManagerEvent.actionFailure,
        eventVersion: state.eventVersion + 1,
        errorMessage: message,
      ),
    );
  }

  Future<void> _finishMutation(
    Either<Failure, Unit> result,
    PhotoManagerEvent success,
  ) async {
    if (isClosed) return;
    Failure? failure;
    result.fold<void>((f) => failure = f, (_) {});
    final failed = failure;
    if (failed != null) {
      emit(
        state.copyWith(
          clearInFlight: true,
          event: PhotoManagerEvent.actionFailure,
          eventVersion: state.eventVersion + 1,
          errorMessage: failed.message,
        ),
      );
      // The message goes out FIRST, then the grid catches up: the listener
      // fires on the event, so the user is told what happened before the tile
      // disappears under them.
      if (_isMissingImage(failed)) await load();
      return;
    }
    await _reloadAfterMutation(success);
  }

  /// The server has no such image. Whatever else this grid believes about it
  /// is suspect too, so the tile is not left sitting there inviting a second
  /// tap that can only fail the same way.
  bool _isMissingImage(Failure failure) =>
      failure is CodedServerFailure &&
      failure.errorCode == ProfileImageErrorCodes.notFound;
}
