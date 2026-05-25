import 'dart:io';

import 'package:dartz/dartz.dart';

import 'package:qeran/core/errors/errors.dart';

/// Contract for uploading profile images.
///
/// Returns the server success message on success,
/// keeping the domain layer free of data-layer wrappers.
abstract interface class ProfileImageRepository {
  Future<Either<Failure, String>> uploadImages({required List<File> images});
}
