import 'package:equatable/equatable.dart';

enum ChangePasswordStatus { initial, submitting, success, failure }

/// WHERE a failure belongs on screen, which is a separate question from what
/// it says.
///
/// This used to be a list of causes with a single fallback that pinned every
/// non-offline failure under the current-password field. That made the screen
/// state something it did not know: a validation rejection, an expired
/// session or an outright server fault all read as "your current password is
/// wrong". Anchoring is now claimed only for the one code that IS about that
/// field; everything else is announced without blaming an input.
enum ChangePasswordErrorSlot {
  none,

  /// Inline, under the current-password field.
  field,

  /// A snackbar over the sheet — it belongs to the request, not to an input.
  banner,
}

class ChangePasswordState extends Equatable {
  final ChangePasswordStatus status;

  /// Always a locale KEY — never a server sentence. The data source
  /// classifies before this is reached, so the sheet can translate it.
  final String? errorKey;

  final ChangePasswordErrorSlot errorSlot;

  /// Bumped on every outcome so the sheet's listener fires even when two
  /// consecutive failures carry the same kind.
  final int version;

  const ChangePasswordState({
    this.status = ChangePasswordStatus.initial,
    this.errorKey,
    this.errorSlot = ChangePasswordErrorSlot.none,
    this.version = 0,
  });

  bool get isSubmitting => status == ChangePasswordStatus.submitting;

  ChangePasswordState copyWith({
    ChangePasswordStatus? status,
    String? errorKey,
    bool clearError = false,
    ChangePasswordErrorSlot? errorSlot,
    int? version,
  }) =>
      ChangePasswordState(
        status: status ?? this.status,
        errorKey: clearError ? null : (errorKey ?? this.errorKey),
        errorSlot: errorSlot ?? this.errorSlot,
        version: version ?? this.version,
      );

  @override
  List<Object?> get props => [status, errorKey, errorSlot, version];
}
