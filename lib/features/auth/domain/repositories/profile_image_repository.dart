import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/domain/entities/success_response.dart';

abstract interface class ProfileImageRepository {
  Future<Either<Failure, SuccessResponse<dynamic>>> uploadImages({
    required List<File> images,
  });
}
