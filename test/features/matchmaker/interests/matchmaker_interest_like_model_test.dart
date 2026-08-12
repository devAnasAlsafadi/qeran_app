import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/interests/data/models/matchmaker_interest_like_model.dart';

void main() {
  test('carries the server age and expiry into the interest entity', () {
    final entity = MatchmakerInterestLikeModel.fromJson({
      'profileId': 'user-1',
      'name': 'User',
      'status': 0,
      'age': 34,
      'remainingSeconds': 3600,
      'expiresAt': '2026-08-12T18:00:00Z',
      'answers': [
        {'questionId': 1, 'question': 'Residence', 'answer': 'Jordan'},
      ],
    }).toEntity();

    expect(entity.age, 34);
    expect(entity.remainingSeconds, 3600);
    expect(entity.expiresAt?.toUtc(), DateTime.utc(2026, 8, 12, 18));
    expect(entity.answers.single.answer, 'Jordan');
  });
}
