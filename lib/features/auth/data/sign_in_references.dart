import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// The short reference a failed Google or Apple sign-in carries, shown small
/// under the failure message (run 7, item 3b). The app has no crash reporter,
/// and a shipped iPhone's log reaches only a Mac with the phone plugged in, so
/// the user's screenshot is how we learn which stage failed and why:
///
/// - `G-…` Google's own sheet: its code, or `G-NET-<n>` for a network error
///   inside Google's exchange (an `NSURLErrorDomain` error), `G-OS-<n>` for
///   another system error, `G-APP` for anything else;
/// - `A-…` Apple's sheet;
/// - `F-<code>` Firebase's refusal, its own code;
/// - our server's `S-…` and the network's `NET-…` are named in the
///   presentation layer, from the failure that reaches it.

String googleReference(GoogleSignInExceptionCode code) => switch (code) {
  GoogleSignInExceptionCode.canceled => 'G-CANCEL',
  GoogleSignInExceptionCode.interrupted => 'G-INTERRUPTED',
  GoogleSignInExceptionCode.clientConfigurationError => 'G-CLIENT-CONFIG',
  GoogleSignInExceptionCode.providerConfigurationError => 'G-PROVIDER-CONFIG',
  GoogleSignInExceptionCode.uiUnavailable => 'G-NO-UI',
  GoogleSignInExceptionCode.userMismatch => 'G-USER-MISMATCH',
  GoogleSignInExceptionCode.unknownError => 'G-UNKNOWN',
};

/// A failure Google's plugin didn't classify. On iOS a system error arrives as
/// a `PlatformException` coded `"<domain>: <number>"`.
String googlePlatformReference(Object error) {
  if (error is! PlatformException) return 'G-APP';
  final match = RegExp(r'^(.+): (-?\d+)$').firstMatch(error.code);
  if (match == null) return 'G-OS';
  final kind = match.group(1) == 'NSURLErrorDomain' ? 'NET' : 'OS';
  final number = match.group(2)!;
  return 'G-$kind${number.startsWith('-') ? number : '-$number'}';
}

String appleReference(AuthorizationErrorCode code) => switch (code) {
  AuthorizationErrorCode.canceled => 'A-CANCEL',
  AuthorizationErrorCode.failed => 'A-FAILED',
  AuthorizationErrorCode.invalidResponse => 'A-INVALID',
  AuthorizationErrorCode.notHandled => 'A-NOT-HANDLED',
  AuthorizationErrorCode.notInteractive => 'A-NOT-INTERACTIVE',
  AuthorizationErrorCode.unknown => 'A-UNKNOWN',
};

String firebaseReference(String code) => 'F-$code';
