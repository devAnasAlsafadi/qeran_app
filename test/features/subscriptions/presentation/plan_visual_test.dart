import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/features/subscriptions/presentation/widgets/plan_visual.dart';

void main() {
  group('PlanVisual.parseColor', () {
    test('parses #RRGGBB into a Color', () {
      expect(
        PlanVisual.parseColor('#D4AF37'),
        equals(const Color(0xFFD4AF37)),
      );
      expect(
        PlanVisual.parseColor('#9333EA'),
        equals(const Color(0xFF9333EA)),
      );
    });

    test('falls back to AppColors.primary on missing #', () {
      expect(PlanVisual.parseColor('D4AF37'), equals(AppColors.primary));
    });

    test('falls back on empty / wrong length', () {
      expect(PlanVisual.parseColor(''), equals(AppColors.primary));
      expect(PlanVisual.parseColor('#FFF'), equals(AppColors.primary));
      expect(
        PlanVisual.parseColor('#D4AF3712'),
        equals(AppColors.primary),
      );
    });

    test('falls back on non-hex characters', () {
      expect(PlanVisual.parseColor('#ZZZZZZ'), equals(AppColors.primary));
    });
  });

  group('PlanVisual.isUrl', () {
    test('http/https → true', () {
      expect(PlanVisual.isUrl('https://example.com/icon.png'), isTrue);
      expect(PlanVisual.isUrl('http://cdn.app/img.svg'), isTrue);
    });

    test('emoji / plain text → false', () {
      expect(PlanVisual.isUrl('💎'), isFalse);
      expect(PlanVisual.isUrl('Gold'), isFalse);
      expect(PlanVisual.isUrl(''), isFalse);
    });

    test('schemes other than http(s) → false', () {
      expect(PlanVisual.isUrl('file:///path'), isFalse);
      expect(PlanVisual.isUrl('mailto:a@b.com'), isFalse);
    });
  });
}
