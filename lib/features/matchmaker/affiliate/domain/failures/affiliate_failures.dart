import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The signed-in matchmaker isn't enrolled in the affiliate program — the
/// backend answers `/affiliate/summary` with a 404 in that case. Distinct from
/// a real error (network / 500): the UI shows a dedicated "not enrolled" state,
/// not the retryable error state. Mapped from a 404 `CodedServerException` in
/// `AffiliateRepositoryImpl`.
class AffiliateNotEnrolledFailure extends Failure {
  const AffiliateNotEnrolledFailure({super.message = LocaleKeys.errors_generic});
}
