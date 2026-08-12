/// Whether the "your name is still the default" banner has already been
/// answered during this app run.
///
/// Deliberately in-memory and NOT persisted: the prompt should stop nagging
/// once the member has dismissed it or opened the name screen, but it must
/// come back on the next launch while the name is still the placeholder.
class DefaultNameBannerSession {
  bool _hidden = false;

  bool get isHidden => _hidden;

  /// Called both when the banner is dismissed and when the name screen is
  /// opened — visiting the screen counts as answering the prompt, whether or
  /// not a new name was saved.
  void hide() => _hidden = true;

  /// Cleared on sign-out so the next account is prompted on its own terms.
  void reset() => _hidden = false;
}
