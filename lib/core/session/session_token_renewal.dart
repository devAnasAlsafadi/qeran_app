import 'package:dartz/dartz.dart';

import '../errors/errors.dart';
import 'session_expiry.dart';

/// The token a password change answers with: `data.token`, the shape login
/// answers with; null when there is none (before Tariq's deploy).
String? renewedTokenIn(Object? response) {
  if (response is! Map) return null;
  final data = response['data'];
  if (data is! Map) return null;
  final token = data['token'];
  return token is String && token.isNotEmpty ? token : null;
}

/// A password change replaces the session's token: the server refuses the old
/// one from the moment it accepts the change, and answers with the new one.
/// Both apps change passwords through this.
///
/// [run] holds 401 reports while the change is in flight
/// ([SessionExpiry.renewing]) and hands the new token to [_adopt] before they
/// are judged, so a 401 the old token met meanwhile signs no one out. A change
/// that brings no token keeps the current one.
class SessionTokenRenewal {
  SessionTokenRenewal({
    required SessionExpiry expiry,
    required Future<void> Function(String token) adopt,
  }) : _expiry = expiry,
       _adopt = adopt;

  final SessionExpiry _expiry;
  final Future<void> Function(String token) _adopt;

  Future<Either<Failure, Unit>> run(
    Future<Either<Failure, String?>> Function() change,
  ) => _expiry.renewing(() async {
    final result = await change();
    final token = result.fold((_) => null, (token) => token);
    if (token != null) await _adopt(token);
    return result.map((_) => unit);
  });
}
