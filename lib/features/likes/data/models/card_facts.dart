/// The compact facts an Interests row may carry under the name: age, country
/// of residence, job. Shared by the Sent / Received rows (`likes/outgoing`,
/// `likes/incoming`) and the Mutual rows (`matches`), so all three read the
/// same fields.
///
/// Read in Tariq's order (TQ16): the row's own `age` (a number),
/// `residenceCountry` and `job` (display text); then an `answers[]` item by
/// its `key` (`residenceCountry`, `jobTitle`). A locked row carries no
/// residence or job, so none shows.
///
/// Until his next deploy sends those fields, an answer without a `key` is
/// still matched on its question's words. That fallback is fragile (it takes
/// any question containing the word) and goes with the deploy (`14`, TQ16).
class CardFacts {
  final int? age;
  final String? residence;
  final String? job;

  const CardFacts({this.age, this.residence, this.job});

  factory CardFacts.fromJson(Map<String, dynamic> json) => CardFacts(
    age: _int(json['age']) ?? _int(_byQuestion(json, const ['العمر', 'age'])),
    residence:
        _text(json['residenceCountry']) ??
        _byKey(json, 'residenceCountry') ??
        _byQuestion(json, const ['إقامة', 'اقامة', 'residence']),
    job:
        _text(json['job']) ??
        _byKey(json, 'jobTitle') ??
        _byQuestion(json, const ['مهنة', 'وظيفة', 'job', 'occupation']),
  );

  static int? _int(Object? raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString().trim() ?? '');
  }

  static String? _text(Object? raw) {
    final value = raw?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  static Iterable<Map<dynamic, dynamic>> _answers(Map<String, dynamic> json) {
    final answers = json['answers'];
    return answers is List ? answers.whereType<Map>() : const [];
  }

  /// The answer whose `key` is [key].
  static String? _byKey(Map<String, dynamic> json, String key) {
    for (final answer in _answers(json)) {
      if (answer['key'] != key) continue;
      final value = _text(answer['answer']);
      if (value != null) return value;
    }
    return null;
  }

  /// TO REMOVE after Tariq's next deploy (`14`, TQ16): an answer with no `key`
  /// whose question contains one of [terms]. A keyed answer is never read by
  /// its words: its key says what it is.
  static String? _byQuestion(Map<String, dynamic> json, List<String> terms) {
    for (final answer in _answers(json)) {
      if (_text(answer['key']) != null) continue;
      final question = answer['question']?.toString().toLowerCase() ?? '';
      if (!terms.any(question.contains)) continue;
      final value = _text(answer['answer']);
      if (value != null) return value;
    }
    return null;
  }
}
