/// The compact facts an Interests row may carry under the name: age, country
/// of residence, job. Shared by the Sent / Received rows (`likes/outgoing`,
/// `likes/incoming`) and the Mutual rows (`matches`), so all three read the
/// same keys.
///
/// Each comes from a direct key when the server sends one, else from the
/// row's `answers[]` (`{question, answer}`), matched on the question's text.
/// TQ16 asks Tariq for the direct keys on every row; the text match is the
/// fallback until then, and is fragile by nature (it takes any question
/// containing the word).
class CardFacts {
  final int? age;
  final String? residence;
  final String? job;

  const CardFacts({this.age, this.residence, this.job});

  factory CardFacts.fromJson(Map<String, dynamic> json) => CardFacts(
    age: _age(json),
    residence: _fact(
      json,
      directKeys: const ['residence', 'countryOfResidence', 'residenceCountry'],
      questionTerms: const ['إقامة', 'اقامة', 'residence'],
    ),
    job: _fact(
      json,
      directKeys: const ['job', 'occupation', 'profession'],
      questionTerms: const ['مهنة', 'وظيفة', 'job', 'occupation'],
    ),
  );

  static int? _age(Map<String, dynamic> json) {
    final direct = _parseInt(json['age']);
    if (direct != null) return direct;
    final answer = _fact(
      json,
      directKeys: const [],
      questionTerms: const ['العمر', 'age'],
    );
    return _parseInt(answer);
  }

  static int? _parseInt(Object? raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString().trim() ?? '');
  }

  static String? _fact(
    Map<String, dynamic> json, {
    required List<String> directKeys,
    required List<String> questionTerms,
  }) {
    for (final key in directKeys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    final answers = json['answers'];
    if (answers is! List) return null;
    for (final raw in answers) {
      if (raw is! Map) continue;
      final question = raw['question']?.toString().toLowerCase() ?? '';
      if (!questionTerms.any(question.contains)) continue;
      final answer = raw['answer']?.toString().trim();
      if (answer != null && answer.isNotEmpty) return answer;
    }
    return null;
  }
}
