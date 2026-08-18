import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/profile/data/models/owner_image_model.dart';

/// Both profile endpoints now return the image url, so the model simply
/// resolves what it is given. The id-derived fallback that covered the gap is
/// gone; what remains is that a relative path still becomes absolute, and that
/// a missing url degrades to empty rather than to the bare origin.
void main() {
  Map<String, dynamic> json({Object? url, bool includeUrl = true}) => {
    'id': 'abc-123',
    if (includeUrl) 'url': url,
    'isProfile': true,
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

  test('a relative url missing its leading slash still resolves cleanly', () {
    final entity = OwnerImageModel.fromJson(
      json(url: 'api/users/profile-images/abc-123'),
    ).toEntity();
    expect(
      entity.url,
      'https://qeranadmin-001-site1.rtempurl.com/api/users/profile-images/abc-123',
      reason: 'gluing the path straight onto the host would break the domain',
    );
  });

  test('a missing url yields empty, not the bare origin', () {
    // Empty reads as "no photo" everywhere downstream; the origin alone would
    // read as a real url and fail as a silently broken image.
    for (final payload in [json(includeUrl: false), json(url: null)]) {
      expect(OwnerImageModel.fromJson(payload).toEntity().url, isEmpty);
    }
  });

  test('the other fields still parse', () {
    final entity = OwnerImageModel.fromJson(
      json(url: '/api/users/profile-images/abc-123'),
    ).toEntity();
    expect(entity.id, 'abc-123');
    expect(entity.isProfile, isTrue);
  });
}
