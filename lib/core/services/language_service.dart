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

  /// The ISO-639-1 language code of the currently active locale (e.g. `'ar'`, `'en'`).
  String get currentLanguage => _currentLanguage;

  /// Called by the UI layer (QeranApp) whenever the active locale changes.
  void setLanguage(String languageCode) {
    _currentLanguage = languageCode;
  }
}
