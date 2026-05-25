import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/chat/data/models/matchmaker_info_model.dart';

void main() {
  group('MatchmakerInfoModel — parsing', () {
    test('full payload — URL resolved to absolute', () {
      final entity = MatchmakerInfoModel.fromJson({
        'matchmakerId': 'mm-guid',
        'name': 'أم محمد',
        'profileImageUrl': '/api/users/profile-images/mm-guid',
        'conversationId': 42,
      }).toEntity();

      expect(entity.matchmakerId, 'mm-guid');
      expect(entity.name, 'أم محمد');
      expect(entity.conversationId, 42);
      expect(entity.profileImageUrl, isNotNull);
      expect(entity.profileImageUrl!, startsWith('http'));
    });

    test('null profileImageUrl is kept null (no resolution)', () {
      final entity = MatchmakerInfoModel.fromJson({
        'matchmakerId': 'mm',
        'name': 'X',
        'profileImageUrl': null,
        'conversationId': 1,
      }).toEntity();
      expect(entity.profileImageUrl, isNull);
    });

    test('empty profileImageUrl is kept null', () {
      final entity = MatchmakerInfoModel.fromJson({
        'matchmakerId': 'mm',
        'name': 'X',
        'profileImageUrl': '',
        'conversationId': 1,
      }).toEntity();
      expect(entity.profileImageUrl, isNull);
    });

    test('conversationId as numeric string', () {
      final entity = MatchmakerInfoModel.fromJson({
        'matchmakerId': 'mm',
        'name': 'X',
        'profileImageUrl': null,
        'conversationId': '42',
      }).toEntity();
      expect(entity.conversationId, 42);
    });
  });
}
