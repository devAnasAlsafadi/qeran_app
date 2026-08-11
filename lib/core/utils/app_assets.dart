class AppAssets {
  static const String translations = 'assets/translations';
  static const String _imagePath = 'assets/images/';
  static const String _iconPath = 'assets/icons/';
  static const String logo = '${_imagePath}logo.png';
  static const String logoDark = '${_imagePath}splash_logo.png';
  static const String splashLogo = '${_imagePath}splash_logo.png';
  static const String splashSymbol = '${_imagePath}splash_symbol.png';
  static const String genderMale = '${_imagePath}gender_male.webp';
  static const String genderFemale = '${_imagePath}gender_female.webp';
  static const String essencePortrait =
      '${_imagePath}onboarding/essence_portrait.jpg';

  /// Clean (unblurred) privacy hero portrait for the onboarding blur-reveal —
  /// blur is applied at runtime, so the source must be sharp. Covered by the
  /// `assets/images/` directory declaration in pubspec (no per-file entry).
  static const String welcomePortrait = '${_imagePath}welcome_portrait.webp';
  static const String googleLogo = '${_iconPath}google_logo.svg';
}
