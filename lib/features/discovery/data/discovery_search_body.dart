import 'package:qeran/core/app_logger.dart';

final _bracketed = RegExp(r'^(QuestionFilters|RangeFrom|RangeTo)\[(\d+)\]$');

/// The `POST Discovery/search` body (`DiscoveryFilterDto`) from the flat map
/// `DiscoveryFilterCubit.buildPayload()` makes (`QuestionFilters[18]`,
/// `RangeFrom[5]`, `RangeTo[5]`): each key goes into its dictionary under the
/// question id, ranges as numbers. Empty dictionaries are left out, so no
/// filter sends only `page` and `pageSize` (run 11: the filters left the query
/// string).
Map<String, dynamic> discoverySearchBody({
  required int page,
  required int pageSize,
  Map<String, String>? filters,
}) {
  final questions = <String, String>{};
  final from = <String, num>{};
  final to = <String, num>{};
  filters?.forEach((key, value) {
    final match = _bracketed.firstMatch(key);
    final id = match?.group(2);
    final number = num.tryParse(value);
    switch (match?.group(1)) {
      case 'QuestionFilters':
        questions[id!] = value;
      case 'RangeFrom' when number != null:
        from[id!] = number;
      case 'RangeTo' when number != null:
        to[id!] = number;
      default:
        AppLogger.warning('Search filter dropped: $key', tag: 'DISCOVERY');
    }
  });
  return {
    'page': page,
    'pageSize': pageSize,
    if (questions.isNotEmpty) 'questionFilters': questions,
    if (from.isNotEmpty) 'rangeFrom': from,
    if (to.isNotEmpty) 'rangeTo': to,
  };
}
