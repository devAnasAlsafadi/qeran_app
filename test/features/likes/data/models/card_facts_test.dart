import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/data/models/card_facts.dart';

/// TQ16 (Tariq, 2026-10-13): the Interests rows carry `age`,
/// `residenceCountry` and `job`; their `answers[]` items carry a `key`
/// (`residenceCountry`, `jobTitle`). The facts are read in that order, and a
/// question's words only until his next deploy.
void main() {
  (int?, String?, String?) facts(Map<String, dynamic> row) {
    final f = CardFacts.fromJson(row);
    return (f.age, f.residence, f.job);
  }

  Map<String, dynamic> answer(String question, String value, [String? key]) => {
    'question': question,
    'answer': value,
    'key': ?key,
  };

  test('the direct fields', () {
    expect(facts({'age': 29, 'residenceCountry': 'الكويت', 'job': 'مهندس'}), (
      29,
      'الكويت',
      'مهندس',
    ));
  });

  test('the direct fields win over the answers', () {
    final row = {
      'residenceCountry': 'الكويت',
      'job': 'مهندس',
      'answers': [
        answer('بلد الإقامة', 'قطر', 'residenceCountry'),
        answer('المسمى الوظيفي', 'معلم', 'jobTitle'),
      ],
    };
    expect(facts(row), (null, 'الكويت', 'مهندس'));
  });

  test('an answer by its key, whatever its question says', () {
    final row = {
      'answers': [
        answer('أين تسكن؟', 'قطر', 'residenceCountry'),
        answer('ماذا تعمل؟', 'معلمة', 'jobTitle'),
      ],
    };
    expect(facts(row), (null, 'قطر', 'معلمة'));
  });

  test('a keyed answer wins over a matching question without a key', () {
    final row = {
      'answers': [
        answer('بلد الإقامة', 'الأردن'),
        answer('المهنة', 'طبيب'),
        answer('أين تسكن؟', 'قطر', 'residenceCountry'),
        answer('ماذا تعمل؟', 'معلمة', 'jobTitle'),
      ],
    };
    expect(facts(row), (null, 'قطر', 'معلمة'));
  });

  test('another key is never read by its words', () {
    final row = {
      'answers': [
        answer('مكان الإقامة بعد الزواج', 'قطر', 'residenceAfterMarriage'),
        answer('هل تقبل وظيفة الزوجة؟', 'نعم', 'wifeWorks'),
      ],
    };
    expect(facts(row), (null, null, null));
  });

  test('until the deploy: an answer without a key, by its question', () {
    final row = {
      'answers': [
        answer('العمر', '31'),
        answer('بلد الإقامة', 'الأردن'),
        answer('المهنة', 'طبيب'),
      ],
    };
    expect(facts(row), (31, 'الأردن', 'طبيب'));
  });

  test('fields Tariq never named are not read', () {
    final row = {
      'residence': 'الأردن',
      'countryOfResidence': 'الأردن',
      'occupation': 'طبيب',
      'profession': 'طبيب',
    };
    expect(facts(row), (null, null, null));
  });

  test('a locked row: its age alone', () {
    expect(facts({'isLocked': true, 'age': 27}), (27, null, null));
  });

  test('blank values are absent', () {
    final row = {
      'residenceCountry': '  ',
      'job': '',
      'answers': [answer('ماذا تعمل؟', ' ', 'jobTitle')],
    };
    expect(facts(row), (null, null, null));
  });
}
