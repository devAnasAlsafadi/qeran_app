/// All photo-upload states carry the current image list and primary index
/// so the UI can always render them without reading mutable cubit fields.
sealed class PhotoUploadState {
  final List<String> imagePaths;
  final int primaryIndex;

  const PhotoUploadState({this.imagePaths = const [], this.primaryIndex = 0});

  bool get hasMinimumImages => imagePaths.isNotEmpty;
  bool get canAddMore => imagePaths.length < 5;
}

/// Initial state — no images selected yet.
final class PhotoUploadInitial extends PhotoUploadState {
  const PhotoUploadInitial();
}

/// User is actively editing images (add / remove / set primary).
final class PhotoUploadEditing extends PhotoUploadState {
  const PhotoUploadEditing({
    required super.imagePaths,
    required super.primaryIndex,
  });
}

/// Upload is in progress — show spinner, disable controls.
final class PhotoUploadUploading extends PhotoUploadState {
  const PhotoUploadUploading({
    required super.imagePaths,
    required super.primaryIndex,
  });
}

/// Upload succeeded OR user tapped "Skip".
/// Flag is already persisted — UI should navigate to Home.
final class PhotoUploadSuccess extends PhotoUploadState {
  final String successMessage;

  const PhotoUploadSuccess({this.successMessage = ''});
}

/// Upload failed — retain images so the user can retry.
final class PhotoUploadFailure extends PhotoUploadState {
  final String errorMessage;

  const PhotoUploadFailure({
    required this.errorMessage,
    required super.imagePaths,
    required super.primaryIndex,
  });
}

/// Client-side image validation failed (size, extension, or missing file).
final class PhotoUploadValidationError extends PhotoUploadState {
  final String errorMessage;

  const PhotoUploadValidationError({
    required this.errorMessage,
    required super.imagePaths,
    required super.primaryIndex,
  });
}
