import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/features/profile/data/models/owner_image_model.dart';

/// `GET /users/profile-images` ships the images without a `url`, while
/// `GET /profile` returns the same ids WITH one. Until the backend fills the
/// gap the location is derived from the id — and the derived value must stop
/// being used the moment a real one arrives.
void main() {
  Map<String, dynamic> json({Object? url, bool includeUrl = true}) => {
    'id': 'abc-123',
    if (includeUrl) 'url': url,
    'isProfile': true,
    'isApproved': true,
  };

  test('a server-supplied absolute url is used as-is', () {
    final entity = OwnerImageModel.fromJson(
      json(url: 'https://cdn.example.com/a.jpg'),
    ).toEntity();
    expect(entity.url, 'https://cdn.example.com/a.jpg');
  });

  test('a server-supplied relative url is resolved against the origin', () {
    final entity = OwnerImageModel.fromJson(
      json(url: '/api/users/profile-images/abc-123'),
    ).toEntity();
    expect(
      entity.url,
      'https://qeranadmin-001-site1.rtempurl.com/api/users/profile-images/abc-123',
    );
  });

  test('a missing url falls back to the id-derived location', () {
    final entity = OwnerImageModel.fromJson(json(includeUrl: false)).toEntity();
    expect(entity.url, '${EndPoints.baseUrl}${EndPoints.profileImage('abc-123')}');
    expect(
      entity.url,
      'https://qeranadmin-001-site1.rtempurl.com/api/users/profile-images/abc-123',
      reason: 'must match the shape GET /profile returns for the same id',
    );
  });

  test('an explicitly null url falls back too', () {
    final entity = OwnerImageModel.fromJson(json(url: null)).toEntity();
    expect(entity.url, contains('/api/users/profile-images/abc-123'));
  });

  test('an empty-string url falls back rather than resolving to the origin', () {
    final entity = OwnerImageModel.fromJson(json(url: '')).toEntity();
    expect(entity.url, isNot('https://qeranadmin-001-site1.rtempurl.com/'));
    expect(entity.url, contains('/api/users/profile-images/abc-123'));
  });

  test('the other fields still parse', () {
    final entity = OwnerImageModel.fromJson(json(includeUrl: false)).toEntity();
    expect(entity.id, 'abc-123');
    expect(entity.isProfile, isTrue);
    expect(entity.isApproved, isTrue);
  });
}
