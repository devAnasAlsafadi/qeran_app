import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../json_parsers.dart';

/// The envelope's `data` object. A success with no object in it is a server
/// fault, surfaced as an error rather than an empty post or comment.
Map<String, dynamic> communityEnvelopeData(dynamic body) =>
    parseNullableMap(body is Map ? body['data'] : null) ??
    (throw ServerException(message: LocaleKeys.errors_unexpected));
