import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/data/models/discovery_filter_question_model.dart';
import 'package:qeran/features/discovery/domain/entities/filter_question_type.dart';

void main() {
  group('DiscoveryFilterQuestionModel — backend range fields', () {
    test('parses height with isRange/minValue/maxValue/unit', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 5,
        'question': 'الطول',
        'type': 'height',
        'isRange': true,
        'minValue': 140,
        'maxValue': 210,
        'unit': 'سم',
        'options': null,
      }).toEntity();
      expect(e.id, 5);
      expect(e.type, FilterQuestionType.height);
      expect(e.isRange, isTrue);
      expect(e.minValue, 140);
      expect(e.maxValue, 210);
      expect(e.unit, 'سم');
      expect(e.options, isNull);
      expect(e.effectiveMin, 140);
      expect(e.effectiveMax, 210);
    });

    test('parses weight with backend unit "كيلو"', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 6,
        'question': 'الوزن',
        'type': 'weight',
        'isRange': true,
        'minValue': 40,
        'maxValue': 150,
        'unit': 'كيلو',
        'options': null,
      }).toEntity();
      expect(e.type, FilterQuestionType.weight);
      expect(e.unit, 'كيلو');
      expect(e.effectiveMin, 40);
      expect(e.effectiveMax, 150);
    });

    test('parses date as age range with unit "سنة"', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 1,
        'question': 'العمر',
        'type': 'date',
        'isRange': true,
        'minValue': 18,
        'maxValue': 60,
        'unit': 'سنة',
        'options': null,
      }).toEntity();
      expect(e.type, FilterQuestionType.date);
      expect(e.isRange, isTrue);
      expect(e.minValue, 18);
      expect(e.maxValue, 60);
      expect(e.unit, 'سنة');
    });

    test('range with missing min/max/unit falls back per type', () {
      // Height with no backend metadata → 50..200, no unit forced.
      final h = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 5,
        'question': 'الطول',
        'type': 'height',
        'isRange': true,
      }).toEntity();
      expect(h.effectiveMin, 50);
      expect(h.effectiveMax, 200);
      expect(h.unit, isNull);

      // Date defaults to 18..80.
      final d = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 1,
        'question': 'العمر',
        'type': 'date',
        'isRange': true,
      }).toEntity();
      expect(d.effectiveMin, 18);
      expect(d.effectiveMax, 80);
    });
  });

  group('DiscoveryFilterQuestionModel — non-range types', () {
    test('parses select with options', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 11,
        'question': 'الجنسية',
        'type': 'select',
        'isRange': false,
        'options': [
          {'value': 'Saudi', 'display': 'سعودي'},
          {'value': 'Other', 'display': 'أخرى'},
        ],
      }).toEntity();
      expect(e.type, FilterQuestionType.select);
      expect(e.isRange, isFalse);
      expect(e.options!.length, 2);
      expect(e.options!.first.value, 'Saudi');
      expect(e.options!.first.display, 'سعودي');
    });

    test('parses radio', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 18,
        'question': 'الحالة الاجتماعية',
        'type': 'radio',
        'isRange': false,
        'options': [
          {'value': 'Single', 'display': 'عازب'},
        ],
      }).toEntity();
      expect(e.type, FilterQuestionType.radio);
    });

    test('parses checkbox', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 21,
        'question': 'لغات',
        'type': 'checkbox',
        'isRange': false,
        'options': [
          {'value': 'AR', 'display': 'العربية'},
          {'value': 'EN', 'display': 'الإنجليزية'},
        ],
      }).toEntity();
      expect(e.type, FilterQuestionType.checkbox);
      expect(e.options!.length, 2);
    });

    test('parses interests', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 22,
        'question': 'اهتمامات',
        'type': 'interests',
        'isRange': false,
        'options': [
          {'value': 'Honest', 'display': 'صادق'},
        ],
      }).toEntity();
      expect(e.type, FilterQuestionType.interests);
    });

    test('parses text', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 30,
        'question': 'اسم',
        'type': 'text',
        'isRange': false,
        'options': null,
      }).toEntity();
      expect(e.type, FilterQuestionType.text);
      expect(e.options, isNull);
    });
  });

  group('DiscoveryFilterQuestionModel — resilience', () {
    test('unknown wire type maps to FilterQuestionType.unknown', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 99,
        'question': 'سؤال جديد',
        'type': 'futureXYZ',
        'isRange': false,
        'options': [
          {'value': 'A', 'display': 'أ'},
        ],
      }).toEntity();
      expect(e.type, FilterQuestionType.unknown);
      expect(e.options!.single.value, 'A');
    });

    test('missing isRange defaults to false', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 50,
        'question': 'x',
        'type': 'select',
      }).toEntity();
      expect(e.isRange, isFalse);
    });

    test('empty json parses without crash', () {
      final m = DiscoveryFilterQuestionModel.fromJson(const {});
      expect(m.questionId, 0);
      expect(m.question, '');
      expect(m.toEntity().type, FilterQuestionType.unknown);
      expect(m.isRange, isFalse);
    });

    test('case-insensitive type mapping', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 1,
        'type': 'CHECKBOX',
      }).toEntity();
      expect(e.type, FilterQuestionType.checkbox);
    });
  });
}
