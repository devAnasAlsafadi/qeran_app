import 'package:qeran/generated/locale_keys.g.dart';

/// Machine-readable `errorCode`s the profile-image endpoints return on a
/// failure envelope (HTTP 200 with `status: 0`). Branch on THESE, never on the
/// response `message` — the backend sends its own Arabic prose there, and
/// shipping it verbatim both bypasses our translations and couples the UI to
/// server copy.
///
/// `IMAGE_NOT_FOUND` used to arrive as an HTTP 404 and now comes through the
/// same status:0 envelope as the rest, so there is nothing left on these
/// endpoints that branches on a transport status.
class ProfileImageErrorCodes {
  const ProfileImageErrorCodes._();

  /// DELETE against the profile's only remaining image.
  ///
  /// The grid withholds the delete control at one photo, so reaching this is a
  /// race: another device removed the sibling between our list loading and the
  /// tap landing.
  static const String lastOne = 'IMAGE_LAST_ONE';

  /// DELETE or PUT set-main against an id the server does not have — removed
  /// elsewhere, or never belonging to this user.
  static const String notFound = 'IMAGE_NOT_FOUND';

  /// POST that would take the profile past the five-photo cap. Also a race:
  /// the grid stops offering an add tile at five.
  static const String limitReached = 'IMAGE_LIMIT_REACHED';

  /// POST carrying a file above the server's 5 MB ceiling.
  static const String tooLarge = 'IMAGE_TOO_LARGE';

  /// POST carrying a file whose type the server refuses.
  static const String invalidType = 'IMAGE_INVALID_TYPE';

  /// POST carrying no files at all.
  ///
  /// Unreachable from this client — `upload()` returns early without staged
  /// files, `uploadAndSetMain` always sends exactly one, and `postMultipart`
  /// throws on an empty list. Mapped anyway so a future caller that slips past
  /// all three still produces a translated message instead of Arabic prose.
  static const String imageRequired = 'IMAGE_REQUIRED';

  /// The message each code should show.
  ///
  /// Three codes deliberately share a string with a client-side pre-check
  /// rather than owning a second one: the pre-check and the server guard state
  /// the same rule, and two strings for one rule drift apart the moment either
  /// side changes. `IMAGE_REQUIRED` maps to the generic error because it
  /// cannot be reached, and a bespoke sentence for it would be dead copy.
  static const Map<String, String> _localeKeys = {
    lastOne: LocaleKeys.profile_photos_last_one,
    notFound: LocaleKeys.profile_photos_not_found,
    limitReached: LocaleKeys.profile_photos_max_reached,
    tooLarge: LocaleKeys.auth_photo_validation_size,
    invalidType: LocaleKeys.profile_photos_validation_type,
    imageRequired: LocaleKeys.errors_generic,
  };

  /// The locale key for [code], or null when the code is not one of ours —
  /// callers rethrow untouched in that case rather than guessing.
  static String? localeKeyFor(String? code) =>
      code == null ? null : _localeKeys[code];
}
