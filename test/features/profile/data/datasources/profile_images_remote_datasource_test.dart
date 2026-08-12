import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/features/profile/data/datasources/profile_remote_datasource.dart';

class _MockApiConsumer extends Mock implements ApiConsumer {}

void main() {
  late _MockApiConsumer api;
  late ProfileRemoteDataSourceImpl dataSource;

  setUp(() {
    api = _MockApiConsumer();
    dataSource = ProfileRemoteDataSourceImpl(apiConsumer: api);
  });

  test('reads isApproved for every profile image', () async {
    when(() => api.get(EndPoints.profileImages)).thenAnswer(
      (_) async => {
        'status': 1,
        'data': [
          {
            'id': 'approved',
            'url': '/a.jpg',
            'isProfile': true,
            'isApproved': true,
          },
          {
            'id': 'pending',
            'url': '/b.jpg',
            'isProfile': false,
            'isApproved': false,
          },
        ],
      },
    );

    final images = await dataSource.getProfileImages();

    expect(images.map((image) => image.isApproved), [true, false]);
  });

  test('uses the documented add, delete, and set-main endpoints', () async {
    final files = [File('new-photo.jpg')];
    when(
      () => api.postMultipart(
        EndPoints.profileImages,
        files: files,
        fieldName: 'images',
      ),
    ).thenAnswer((_) async => <String, dynamic>{});
    when(
      () => api.delete(EndPoints.profileImage('image-1')),
    ).thenAnswer((_) async => <String, dynamic>{});
    when(
      () => api.put(EndPoints.setMainProfileImage('image-1')),
    ).thenAnswer((_) async => <String, dynamic>{});

    await dataSource.addProfileImages(files);
    await dataSource.deleteProfileImage('image-1');
    await dataSource.setMainProfileImage('image-1');

    verify(
      () => api.postMultipart(
        EndPoints.profileImages,
        files: files,
        fieldName: 'images',
      ),
    ).called(1);
    verify(() => api.delete(EndPoints.profileImage('image-1'))).called(1);
    verify(() => api.put(EndPoints.setMainProfileImage('image-1'))).called(1);
  });
}
