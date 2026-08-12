import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/users/data/models/matchmaker_user_profile_model.dart';
import 'package:qeran/features/matchmaker/users/data/models/matchmaker_user_row_model.dart';
import 'package:qeran/features/matchmaker/users/domain/entities/image_request_status.dart';

/// #5 — the persisted "have I already asked for a photo?" flag.
///
/// Before this field the client had no way to know, so the request button
/// looked identical whether or not a request was outstanding. A local flag was
/// rejected: it would not survive a relaunch and would then lie.

void main() {
  group('MatchmakerImageRequestStatus.fromString', () {
    test('the three documented wire values', () {
      expect(
        MatchmakerImageRequestStatus.fromString('none'),
        MatchmakerImageRequestStatus.none,
      );
      expect(
        MatchmakerImageRequestStatus.fromString('pending'),
        MatchmakerImageRequestStatus.pending,
      );
      expect(
        MatchmakerImageRequestStatus.fromString('approved'),
        MatchmakerImageRequestStatus.approved,
      );
    });

    test('casing and padding are tolerated', () {
      expect(
        MatchmakerImageRequestStatus.fromString(' Pending '),
        MatchmakerImageRequestStatus.pending,
      );
      expect(
        MatchmakerImageRequestStatus.fromString('APPROVED'),
        MatchmakerImageRequestStatus.approved,
      );
    });

    test('absent / null / unknown → none, i.e. pre-rollout behaviour', () {
      // The migration is not applied everywhere yet, so a payload without the
      // field must keep offering the request rather than blocking it.
      expect(
        MatchmakerImageRequestStatus.fromString(null),
        MatchmakerImageRequestStatus.none,
      );
      expect(
        MatchmakerImageRequestStatus.fromString(''),
        MatchmakerImageRequestStatus.none,
      );
      expect(
        MatchmakerImageRequestStatus.fromString('something_new'),
        MatchmakerImageRequestStatus.none,
      );
    });

    test('only pending is the awaiting state', () {
      expect(MatchmakerImageRequestStatus.none.isAwaitingUpload, isFalse);
      expect(MatchmakerImageRequestStatus.pending.isAwaitingUpload, isTrue);
      expect(MatchmakerImageRequestStatus.approved.isAwaitingUpload, isFalse);
    });
  });

  group('profile payload', () {
    Map<String, dynamic> profileJson({
      Object? imageRequestStatus = 'none',
      Object? isAssignedToMe = true,
    }) => {
      'userId': 'u1',
      'name': 'أنس',
      'email': 'a@b.c',
      'gender': 'ذكر',
      'age': 30,
      'profileStatus': 'Visible',
      'hasAnsweredQuestions': true,
      'isAssignedToMe': ?isAssignedToMe,
      'images': const [],
      'placements': const [],
      'imageRequestStatus': ?imageRequestStatus,
    };

    test('parses each state onto the entity', () {
      for (final (wire, expected) in [
        ('none', MatchmakerImageRequestStatus.none),
        ('pending', MatchmakerImageRequestStatus.pending),
        ('approved', MatchmakerImageRequestStatus.approved),
      ]) {
        final entity = MatchmakerUserProfileModel.fromJson(
          profileJson(imageRequestStatus: wire),
        ).toEntity();
        expect(entity.imageRequestStatus, expected, reason: wire);
      }
    });

    test('a payload predating the migration parses to none', () {
      final entity = MatchmakerUserProfileModel.fromJson(
        profileJson(imageRequestStatus: null),
      ).toEntity();
      expect(entity.imageRequestStatus, MatchmakerImageRequestStatus.none);
    });

    test('parses the authoritative assignment flag', () {
      expect(
        MatchmakerUserProfileModel.fromJson(
          profileJson(isAssignedToMe: true),
        ).toEntity().isAssignedToMe,
        isTrue,
      );
      expect(
        MatchmakerUserProfileModel.fromJson(
          profileJson(isAssignedToMe: false),
        ).toEntity().isAssignedToMe,
        isFalse,
      );
    });

    test('an absent assignment flag fails closed to view-only', () {
      final entity = MatchmakerUserProfileModel.fromJson(
        profileJson(isAssignedToMe: null),
      ).toEntity();
      expect(entity.isAssignedToMe, isFalse);
    });
  });

  group('list row payload', () {
    Map<String, dynamic> rowJson({Object? imageRequestStatus}) => {
      'userId': 'u1',
      'fullName': 'أنس',
      'hasProfileImage': false,
      'imageRequestStatus': ?imageRequestStatus,
    };

    test('reads the field when the list DTO carries it', () {
      final row = MatchmakerUserRowModel.fromJson(
        rowJson(imageRequestStatus: 'pending'),
      ).toEntity();
      expect(row.imageRequestStatus, MatchmakerImageRequestStatus.pending);
    });

    test('the documented list DTO (no field) parses to none', () {
      // The backend documents imageRequestStatus on the PROFILE response; the
      // list DTO is not documented to carry it. Absent must be harmless.
      final row = MatchmakerUserRowModel.fromJson(rowJson()).toEntity();
      expect(row.imageRequestStatus, MatchmakerImageRequestStatus.none);
    });
  });
}
