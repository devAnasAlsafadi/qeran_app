import 'package:flutter/widgets.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The short reference a failed Google or Apple sign-in shows under its
/// message, so a screenshot names the cause (run 7, item 3b).
///
/// The sheet and Firebase stages arrive named by the data source
/// (`sign_in_references.dart`). Our server's answer, the network and a timeout
/// reach here as the failure itself, and are named from it: `S-<errorCode>`
/// (or `S-<status>`), `S-TIMEOUT`, `NET-OFFLINE`.
String? signInReference(Failure failure) => switch (failure) {
  AuthFailure(:final reference) => reference,
  OfflineFailure() => 'NET-OFFLINE',
  CodedServerFailure(:final errorCode, :final statusCode)
      when errorCode != null || statusCode != null =>
    'S-${errorCode ?? statusCode}',
  ServerFailure(:final message) when message == LocaleKeys.errors_timeout =>
    'S-TIMEOUT',
  ServerFailure() => 'S',
  _ => null,
};

/// [reference] as the small line under a failed sign-in's message:
/// «رمز المرجع: G-NET-1009» / "Reference: G-NET-1009". Null when there's none.
String? signInReferenceNote(BuildContext context, String? reference) =>
    reference == null
    ? null
    : LocaleKeys.errors_sign_in_reference.t(
        context,
        namedArgs: {'code': reference},
      );
