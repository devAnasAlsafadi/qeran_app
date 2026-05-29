/// Matchmaker (role=Moderator) feature DI registration.
///
/// Intentionally empty for the foundation milestone: the shell + tabs
/// are stateless empty-state screens with no cubits yet. Subsequent
/// milestones add registrations here:
///   • M2 — dashboard + users repositories / cubits
///   • M3 — compatibility-cases
///   • M4 — conversations + colleagues + matchmaker chat bootstrap
///   • M5 — explore
///   • M6 — notifications + account
///
/// Called from `core/di/injection_container.dart`.
Future<void> initMatchmakerDependencies() async {
  // No-op for now. Add `sl.register*` calls per milestone above.
}
