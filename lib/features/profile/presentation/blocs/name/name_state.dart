import 'package:equatable/equatable.dart';

import '../../../domain/entities/my_profile.dart';

enum NameStatus { initial, loading, loaded, failure }

/// One-shot outcomes the screen reacts to (toast / pop), consumed via
/// `eventVersion` so a rebuild never replays them.
enum NameEvent { none, saved, saveFailed }

class NameState extends Equatable {
  const NameState({
    this.status = NameStatus.initial,
    this.profile,
    this.saving = false,
    this.event = NameEvent.none,
    this.eventVersion = 0,
    this.errorMessage,
  });

  final NameStatus status;

  /// The profile the screen renders from, and the BASELINE both fields are
  /// diffed against when deciding what to send. Retained across a save so a
  /// failed write never blanks the form.
  final MyProfile? profile;
  final bool saving;
  final NameEvent event;
  final int eventVersion;

  /// Load failure, or the server's verbatim message on a rejected save.
  /// The backend attributes a rejection to the call, not to a field, so this
  /// one envelope message carries every failure.
  final String? errorMessage;

  /// The saved display name — the baseline the form's field is diffed against.
  String get displayName => profile?.name ?? '';

  /// The saved real name, or null when the member has none on file. Blank is
  /// normalised to null so "absent" and "empty string" are one state here.
  String? get realName {
    final value = profile?.realName?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  NameState copyWith({
    NameStatus? status,
    MyProfile? profile,
    bool? saving,
    NameEvent? event,
    int? eventVersion,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NameState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      saving: saving ?? this.saving,
      event: event ?? this.event,
      eventVersion: eventVersion ?? this.eventVersion,
      // A new attempt clears what the previous one reported.
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
