import 'dart:io';

import 'package:dartz/dartz.dart';

import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/repositories/profile_image_repository.dart';
import '../datasources/profile_image_remote_datasource.dart';

class ProfileImageRepositoryImpl
    with BaseRepository
    implements ProfileImageRepository {
  final ProfileImageRemoteDataSource _dataSource;

  const ProfileImageRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, String>> uploadImages({required List<File> images}) {
    return executeApiCall(() async {
      final response = await _dataSource.uploadImages(images: images);
      // Map SuccessResponse → plain String (domain stays clean)
      return response.message ?? LocaleKeys.auth_photo_upload_success;
    });
  }
}
