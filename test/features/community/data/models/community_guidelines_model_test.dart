import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/data/models/community_guidelines_model.dart';

import '../../fixtures/community_fixtures.dart';

void main() {
  group('CommunityGuidelinesModel', () {
    test('the member text: version, intro and five icon names in order', () {
      final g = CommunityGuidelinesModel.fromJson(guidelines()).toEntity();

      expect(g.version, 3);
      expect(g.lastUpdatedAt?.toUtc(), DateTime.utc(2026, 10, 1, 9));
      expect(g.introAr, 'مجتمع قِران مساحة للتعلّم.');
      expect(g.introEn, 'Qeran Community is a place to learn.');
      expect(g.sections.map((s) => s.iconName),
          ['block', 'phone_disabled', 'lock', 'campaign', 'flag']);
      expect(g.sections.first.titleEn, 'Rule 1');
      expect(g.sections.first.bodyAr, 'نص 1');
    });

    test('the matchmaker text arrives in the same shape', () {
      final g = CommunityGuidelinesModel.fromJson(guidelines(icons: const [
        'lightbulb',
        'lock',
        'phone_disabled',
        'block',
        'shield',
      ])).toEntity();

      expect(g.sections.map((s) => s.iconName).first, 'lightbulb');
      expect(g.sections, hasLength(5));
    });

    test('a missing icon is an empty name (the screen maps it to a fallback)',
        () {
      final json = guidelines();
      (json['sections'] as List).first.remove('icon');

      final g = CommunityGuidelinesModel.fromJson(json).toEntity();

      expect(g.sections.first.iconName, '');
    });
  });
}
