/// A lightweight, context-free singleton that holds the current app language.
///
/// Acts as the bridge between the UI layer (which has a [BuildContext] and
/// therefore access to [easy_localization]) and the API layer (which has no
/// [BuildContext]).
///
/// The service is synced by [QeranApp.build] every time [easy_localization]
/// changes the locale, so the API layer always reads the correct value.
class LanguageService {
  String _currentLanguage = 'ar'; // mirrors EasyLocalization startLocale

  /// False until the first sync from the real saved locale has happened.
  bool _synced = false;

  /// The ISO-639-1 language code of the currently active locale (e.g. `'ar'`, `'en'`).
  String get currentLanguage => _currentLanguage;

  /// Called by the UI layer (QeranApp) whenever the active locale changes.
  ///
  /// Returns true only for a real SWITCH — a language replacing one the app was
  /// already running in. The first call after launch merely adopts the saved
  /// locale and returns false, so cold start doesn't look like a switch and
  /// re-fetch everything it was about to fetch anyway.
  bool setLanguage(String languageCode) {
    final switched = _synced && languageCode != _currentLanguage;
    _currentLanguage = languageCode;
    _synced = true;
    return switched;
  }
}
