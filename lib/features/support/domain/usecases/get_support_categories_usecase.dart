import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/support_category.dart';
import '../repositories/support_repository.dart';

/// Loads the support problem-type list for the form dropdown.
class GetSupportCategoriesUseCase {
  final SupportRepository _repository;
  const GetSupportCategoriesUseCase(this._repository);

  Future<Either<Failure, List<SupportCategory>>> call() =>
      _repository.getCategories();
}
