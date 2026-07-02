import 'package:equatable/equatable.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../../domain/entities/validate_code_response.dart';

sealed class PackagePurchaseState extends Equatable {
  const PackagePurchaseState();

  @override
  List<Object?> get props => const [];
}

/// Nothing in progress — the paywall's resting state.
final class PackagePurchaseIdle extends PackagePurchaseState {
  const PackagePurchaseIdle();
}

/// Transient — a `/validate-code` request is in flight.
final class PackagePurchaseValidatingCode extends PackagePurchaseState {
  const PackagePurchaseValidatingCode();
}

/// The code was validated (may or may not be `valid` — inspect [response] to
/// render the discount preview or an inline message).
final class PackagePurchaseCodeValidationSuccess extends PackagePurchaseState {
  final ValidateCodeResponse response;
  const PackagePurchaseCodeValidationSuccess({required this.response});

  @override
  List<Object?> get props => [response];
}

/// The code couldn't be validated (transport error, or `valid:false`).
final class PackagePurchaseCodeValidationFailure extends PackagePurchaseState {
  final String message;
  const PackagePurchaseCodeValidationFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Transient — a store purchase / restore is in flight ("Purchasing").
final class PackagePurchaseInProgress extends PackagePurchaseState {
  const PackagePurchaseInProgress();
}

/// The purchase (or restore) succeeded. [customerInfo] is RC's post-purchase
/// entitlement snapshot; the backend `/current` reconciles in the background.
final class PackagePurchaseSuccess extends PackagePurchaseState {
  final CustomerInfo customerInfo;
  const PackagePurchaseSuccess({required this.customerInfo});

  @override
  List<Object?> get props => [customerInfo];
}

/// The user dismissed the store sheet — a benign, non-error outcome.
final class PackagePurchaseCancelled extends PackagePurchaseState {
  const PackagePurchaseCancelled();
}

/// The purchase failed. [failure] is the typed cause (for logic / telemetry);
/// [userMessage] is the localized key to show.
final class PackagePurchaseFailure extends PackagePurchaseState {
  final Failure failure;
  final String userMessage;
  const PackagePurchaseFailure({
    required this.failure,
    required this.userMessage,
  });

  @override
  List<Object?> get props => [failure, userMessage];
}
