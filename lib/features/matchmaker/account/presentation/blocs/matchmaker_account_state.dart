import 'package:equatable/equatable.dart';

import '../../domain/entities/matchmaker_me.dart';

/// Initial `GET /me` load status.
enum MatchmakerAccountStatus { initial, loading, loaded, failure }

/// Which mutation is currently running (one in-flight slot, guards double-tap).
enum MatchmakerAccountAction {
  savingName,
  uploadingPhoto,
  deactivating,
  changingPassword,
}

/// One-shot outcome the screen listens to (snackbar + post-deactivate redirect).
/// The screen reacts on every [eventVersion] bump and ignores [none].
enum MatchmakerAccountOutcome {
  none,
  saveNameSuccess,
  uploadPhotoSuccess,
  deactivateSuccess,
  changePasswordSuccess,
  failure,
}

/// Routes a [MatchmakerAccountOutcome.failure]: inline in the edit-name sheet
/// ([validation]) / inline in the change-password sheet ([incorrectPassword]) /
/// toast ([generic]). Mirrors the notes feature's error-kind routing.
enum MatchmakerAccountErrorKind { none, validation, incorrectPassword, generic }

class MatchmakerAccountState extends Equatable {
  final MatchmakerAccountStatus status;
  final MatchmakerMe? me;

  /// Error key for the initial load failure (locale key or server text).
  final String? loadErrorKey;

  final MatchmakerAccountAction? inFlight;
  final MatchmakerAccountOutcome outcome;
  final MatchmakerAccountErrorKind errorKind;
  final int eventVersion;

  /// Error text for the most recent action failure — run through `.t(context)`.
  final String? actionErrorKey;

  const MatchmakerAccountState({
    this.status = MatchmakerAccountStatus.initial,
    this.me,
    this.loadErrorKey,
    this.inFlight,
    this.outcome = MatchmakerAccountOutcome.none,
    this.errorKind = MatchmakerAccountErrorKind.none,
    this.eventVersion = 0,
    this.actionErrorKey,
  });

  bool get isBusy => inFlight != null;

  MatchmakerAccountState copyWith({
    MatchmakerAccountStatus? status,
    MatchmakerMe? me,
    String? loadErrorKey,
    bool clearLoadError = false,
    MatchmakerAccountAction? inFlight,
    bool clearInFlight = false,
    MatchmakerAccountOutcome? outcome,
    MatchmakerAccountErrorKind? errorKind,
    int? eventVersion,
    String? actionErrorKey,
    bool clearActionError = false,
  }) {
    return MatchmakerAccountState(
      status: status ?? this.status,
      me: me ?? this.me,
      loadErrorKey: clearLoadError ? null : (loadErrorKey ?? this.loadErrorKey),
      inFlight: clearInFlight ? null : (inFlight ?? this.inFlight),
      outcome: outcome ?? this.outcome,
      errorKind: errorKind ?? this.errorKind,
      eventVersion: eventVersion ?? this.eventVersion,
      actionErrorKey:
          clearActionError ? null : (actionErrorKey ?? this.actionErrorKey),
    );
  }

  @override
  List<Object?> get props => [
        status,
        me,
        loadErrorKey,
        inFlight,
        outcome,
        errorKind,
        eventVersion,
        actionErrorKey,
      ];
}
