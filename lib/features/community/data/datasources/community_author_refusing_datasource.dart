import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'community_author_remote_datasource.dart';

/// The author's paths in a dev-flag build (`COMMUNITY_MOCK`, never release):
/// every call fails, so a mock post's id never reaches the live server — a
/// delete there could hit a real post with the same id. Every method of the
/// interface, present and future, answers through [noSuchMethod].
class CommunityAuthorRefusingDataSource
    implements CommunityAuthorRemoteDataSource {
  const CommunityAuthorRefusingDataSource();

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<Never>.error(
    ServerException(message: LocaleKeys.errors_unexpected),
  );
}
