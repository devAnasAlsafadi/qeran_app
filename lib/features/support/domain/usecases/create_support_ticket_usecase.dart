import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/support_repository.dart';

/// Submits a support ticket (problem type + subject + details).
class CreateSupportTicketUseCase {
  final SupportRepository _repository;
  const CreateSupportTicketUseCase(this._repository);

  Future<Either<Failure, Unit>> call({
    required int categoryId,
    required String subject,
    required String details,
  }) =>
      _repository.createTicket(
        categoryId: categoryId,
        subject: subject,
        details: details,
      );
}
