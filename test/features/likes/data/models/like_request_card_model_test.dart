import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/data/models/like_request_card_model.dart';

void main() {
  test('parses expiresAt and carries it to the domain entity', () {
    final model = LikeRequestCardModel.fromJson({
      'likeRequestId': 12,
      'profileId': 'user-1',
      'name': 'User',
      'status': 0,
      'remainingSeconds': 82800,
      'expiresAt': '2026-08-12T18:00:00Z',
    });

    expect(model.remainingSeconds, 82800);
    expect(model.expiresAt?.toUtc(), DateTime.utc(2026, 8, 12, 18));
    expect(model.toEntity().expiresAt?.toUtc(), DateTime.utc(2026, 8, 12, 18));
  });

  test('archived rows can omit both countdown fields', () {
    final model = LikeRequestCardModel.fromJson({
      'likeRequestId': 13,
      'profileId': 'user-2',
      'name': 'Archived',
      'status': 3,
      'remainingSeconds': null,
      'expiresAt': null,
    });

    expect(model.remainingSeconds, isNull);
    expect(model.expiresAt, isNull);
  });

  test('parses compact profile facts from direct server fields', () {
    final entity = LikeRequestCardModel.fromJson({
      'likeRequestId': 14,
      'profileId': 'user-3',
      'name': 'User',
      'status': 0,
      'age': '31',
      'countryOfResidence': 'Jordan',
      'occupation': 'Engineer',
    }).toEntity();

    expect(entity.age, 31);
    expect(entity.residence, 'Jordan');
    expect(entity.job, 'Engineer');
  });

  test('falls back to flagged answers for compact profile facts', () {
    final entity = LikeRequestCardModel.fromJson({
      'likeRequestId': 15,
      'profileId': 'user-4',
      'name': 'User',
      'status': 0,
      'answers': [
        {'question': 'العمر', 'answer': '29'},
        {'question': 'بلد الإقامة', 'answer': 'Palestine'},
        {'question': 'المهنة', 'answer': 'Teacher'},
      ],
    }).toEntity();

    expect(entity.age, 29);
    expect(entity.residence, 'Palestine');
    expect(entity.job, 'Teacher');
  });
}
