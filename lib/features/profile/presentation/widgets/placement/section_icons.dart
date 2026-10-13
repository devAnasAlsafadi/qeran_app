import 'package:flutter/material.dart';

/// The icon beside a profile section's title, chosen by the section's name
/// (run 7, item 4). The profile payload carries only the name
/// (`placementName`), no id; TQ18 asks Tariq for a stable `categoryId`, and
/// this should key on that once it exists. A name it doesn't know keeps the
/// default.
///
/// Matched on words, not whole names, ignoring Arabic marks and the tatweel,
/// so a respelt «الحياة الزوجيّة» still finds its icon.
IconData sectionIconFor(String name) {
  final bare = name.replaceAll(_marks, '').toLowerCase();
  for (final (words, icon) in _byWords) {
    if (words.any(bare.contains)) return icon;
  }
  return Icons.list_alt_rounded;
}

final RegExp _marks = RegExp('[\u0640\u064B-\u065F\u0670]');

const List<(List<String>, IconData)> _byWords = [
  (['الدين', 'religion'], Icons.mosque_outlined),
  (['الزوجية', 'الزواج', 'marri'], Icons.diversity_1_outlined),
  (
    ['الوظيفة', 'العمل', 'الدخل', 'work', 'job', 'income'],
    Icons.work_outline_rounded,
  ),
  (['التعليم', 'education'], Icons.school_outlined),
  (['الشخصية', 'personal'], Icons.badge_outlined),
];
