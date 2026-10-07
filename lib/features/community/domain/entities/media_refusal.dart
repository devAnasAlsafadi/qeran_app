/// Her media refused by the server's own check, which runs after the app's
/// (contract §9). Each has its notice in the composer.
enum MediaRefusal {
  /// `MEDIA_TOO_LONG`: over `maxVideoDurationSeconds` (BA-A9).
  tooLong,

  /// `MEDIA_TOO_LARGE`: over the size limit (Q3).
  tooLarge,

  /// `MEDIA_INVALID_TYPE`: not a type the server takes (C10).
  invalidType,
}
