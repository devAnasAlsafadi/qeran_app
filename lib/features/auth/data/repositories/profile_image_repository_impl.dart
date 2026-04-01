import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/domain/entities/success_response.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/repositories/profile_image_repository.dart';
import '../datasources/profile_image_remote_datasource.dart';

class ProfileImageRepositoryImpl
    with BaseRepository
    implements ProfileImageRepository {
  final ProfileImageRemoteDataSource _dataSource;

  const ProfileImageRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, SuccessResponse<dynamic>>> uploadImages({
    required List<File> images,
  }) {
    return executeApiCall(() async {
      return await _dataSource.uploadImages(images: images);
    });
  }
}
