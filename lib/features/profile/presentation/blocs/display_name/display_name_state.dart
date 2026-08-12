import 'package:equatable/equatable.dart';

import '../../../domain/entities/display_name_lock.dart';
import '../../../domain/entities/my_profile.dart';

enum DisplayNameStatus { initial, loading, loaded, failure }

/// One-shot outcomes the screen reacts to (toast / pop), consumed via
/// `eventVersion` so a rebuild never replays them.
enum DisplayNameEvent { none, saved, saveFailed }

class DisplayNameState extends Equatable {
  const DisplayNameState({
    this.status = DisplayNameStatus.initial,
    this.profile,
    this.saving = false,
    this.event = DisplayNameEvent.none,
    this.eventVersion = 0,
    this.errorMessage,
  });

  final DisplayNameStatus status;

  /// The profile the screen renders from. Retained across a save so a failed
  /// write never blanks the form.
  final MyProfile? profile;
  final bool saving;
  final DisplayNameEvent event;
  final int eventVersion;

  /// Load failure, or the server's verbatim message on a rejected save.
  final String? errorMessage;

  String get displayName => profile?.name ?? '';

  String? get realName {
    final value = profile?.realName?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  bool get isDefaultName => profile?.isDefaultName ?? false;

  /// The cooldown as the UI counts it, or null when nothing is counting down.
  /// Computed against [now] so the caller controls the clock (and tests can).
  NameLockRemaining? lockRemaining(DateTime now) {
    final until = profile?.displayNameLockedUntil;
    if (until == null) return null;
    return nameLockRemaining(until, now);
  }

  /// Whether the name may be edited right now.
  ///
  /// A member still on the server-assigned placeholder always may — the
  /// cooldown does not apply to them. Otherwise the backend's lock flag holds,
  /// except once its own timestamp has passed: an expired window is treated as
  /// open rather than showing a countdown that reads zero.
  bool canEdit(DateTime now) {
    if (isDefaultName) return true;
    if (!(profile?.isDisplayNameLocked ?? false)) return true;
    return lockRemaining(now) is NameLockElapsed;
  }

  DisplayNameState copyWith({
    DisplayNameStatus? status,
    MyProfile? profile,
    bool? saving,
    DisplayNameEvent? event,
    int? eventVersion,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DisplayNameState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      saving: saving ?? this.saving,
      event: event ?? this.event,
      eventVersion: eventVersion ?? this.eventVersion,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    profile,
    saving,
    event,
    eventVersion,
    errorMessage,
  ];
}
