import 'package:equatable/equatable.dart';

import '../../domain/entities/photo_view_permission.dart';

enum PhotoViewPhase {
  initial,
  loading,

  /// No accepted photo exchange exists for this target. The normal server
  /// `isBlurred` flags remain authoritative.
  unavailable,

  /// Accepted and never opened: show the irreversible reveal action.
  available,

  /// The 60-second server window is active.
  viewing,

  /// The window ended and can never be opened again.
  consumed,

  /// Permission could not be verified. Images fail closed until retry.
  failure,
}

class PhotoViewState extends Equatable {
  final PhotoViewPhase phase;
  final PhotoViewPermission? permission;
  final int secondsRemaining;
  final bool isStarting;
  final bool isConcealed;
  final String? errorMessage;
  final String? actionErrorMessage;

  /// The 60-second window just ran out under the member's eyes. Drives the
  /// one-shot "viewing period has ended" message — the countdown itself is no
  /// longer shown, so the end of the window has to announce itself.
  ///
  /// Only set when the transition came from [PhotoViewPhase.viewing]; arriving
  /// at `consumed` any other way is not something the member witnessed.
  final bool justExpired;
  final int eventVersion;

  const PhotoViewState({
    this.phase = PhotoViewPhase.initial,
    this.permission,
    this.secondsRemaining = 0,
    this.isStarting = false,
    this.isConcealed = false,
    this.errorMessage,
    this.actionErrorMessage,
    this.justExpired = false,
    this.eventVersion = 0,
  });

  PhotoViewState copyWith({
    PhotoViewPhase? phase,
    PhotoViewPermission? permission,
    int? secondsRemaining,
    bool? isStarting,
    bool? isConcealed,
    String? errorMessage,
    bool clearError = false,
    String? actionErrorMessage,
    bool clearActionError = false,
    bool justExpired = false,
    int? eventVersion,
  }) {
    return PhotoViewState(
      justExpired: justExpired,
      phase: phase ?? this.phase,
      permission: permission ?? this.permission,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      isStarting: isStarting ?? this.isStarting,
      isConcealed: isConcealed ?? this.isConcealed,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      actionErrorMessage: clearActionError
          ? null
          : (actionErrorMessage ?? this.actionErrorMessage),
      eventVersion: eventVersion ?? this.eventVersion,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    permission,
    secondsRemaining,
    isStarting,
    isConcealed,
    errorMessage,
    actionErrorMessage,
    justExpired,
    eventVersion,
  ];
}
