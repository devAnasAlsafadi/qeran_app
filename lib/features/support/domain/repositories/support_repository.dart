import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/support_category.dart';

abstract interface class SupportRepository {
  /// Fetches the problem-type list backing the form dropdown. JWT-gated.
  Future<Either<Failure, List<SupportCategory>>> getCategories();

  /// Submits one support ticket. JWT-gated. On a server-rejected envelope the
  /// failure is a [CodedServerFailure] carrying the backend `errorCode`
  /// (e.g. `SUPPORT_TICKETS_LIMIT_REACHED`) so the cubit can branch on it.
  Future<Either<Failure, Unit>> createTicket({
    required int categoryId,
    required String subject,
    required String details,
  });
}
