import 'package:equatable/equatable.dart';

enum ChangePasswordStatus { initial, submitting, success, failure }

/// How a failed change should surface. [incorrectCurrent] covers any
/// non-offline server rejection — after client-side validation (≥8 + regex +
/// confirm-match + differs-from-current) the dominant remaining cause is a
/// wrong current password, so it renders inline under that field.
enum ChangePasswordError { none, incorrectCurrent, offline }

class ChangePasswordState extends Equatable {
  final ChangePasswordStatus status;
  final ChangePasswordError error;

  /// Bumped on every outcome so the sheet's listener fires even when two
  /// consecutive failures carry the same kind.
  final int version;

  const ChangePasswordState({
    this.status = ChangePasswordStatus.initial,
    this.error = ChangePasswordError.none,
    this.version = 0,
  });

  bool get isSubmitting => status == ChangePasswordStatus.submitting;

  ChangePasswordState copyWith({
    ChangePasswordStatus? status,
    ChangePasswordError? error,
    int? version,
  }) =>
      ChangePasswordState(
        status: status ?? this.status,
        error: error ?? this.error,
        version: version ?? this.version,
      );

  @override
  List<Object?> get props => [status, error, version];
}
