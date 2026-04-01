sealed class PhotoUploadState {}

final class PhotoUploadInitial extends PhotoUploadState {}

final class PhotoUploadInProgress extends PhotoUploadState {}

final class PhotoUploadSuccess extends PhotoUploadState {}

final class PhotoUploadFailure extends PhotoUploadState {
  final String message;

  PhotoUploadFailure(this.message);
}
