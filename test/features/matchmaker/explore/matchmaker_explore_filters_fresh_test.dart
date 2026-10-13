import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/discovery/data/models/discovery_filter_question_model.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_question.dart';
import 'package:qeran/features/matchmaker/explore/data/datasources/matchmaker_explore_remote_datasource.dart';
import 'package:qeran/features/matchmaker/explore/data/models/matchmaker_explore_page_model.dart';
import 'package:qeran/features/matchmaker/explore/data/repositories/matchmaker_explore_repository_impl.dart';

/// Her filter sheet asks the server for the list on every open (run 7, item
/// 7). The list used to be kept for the app's whole life, so a question the
/// dashboard made filterable reached her only after she closed the app.
class _Source implements MatchmakerExploreRemoteDataSource {
  int calls = 0;
  List<String> labels = ['العمر'];
  Completer<void>? gate;
  bool fail = false;

  @override
  Future<List<DiscoveryFilterQuestionModel>> getFilters() async {
    calls++;
    await gate?.future;
    if (fail) throw ServerException(message: 'x');
    return [
      for (final (i, label) in labels.indexed)
        DiscoveryFilterQuestionModel.fromJson({
          'questionId': i + 1,
          'question': label,
          'type': 'select',
          'options': [
            {'value': 'a', 'display': 'a'},
          ],
        }),
    ];
  }

  @override
  Future<MatchmakerExplorePageModel> getExplore({
    required int page,
    required int pageSize,
    String? search,
    Gender? gender,
    Map<int, List<String>> questionFilters = const {},
    Map<int, double> rangeFrom = const {},
    Map<int, double> rangeTo = const {},
  }) => throw UnimplementedError();
}

List<String> _labels(Either<Failure, List<DiscoveryFilterQuestion>> result) =>
    result.fold((_) => [], (qs) => [for (final q in qs) q.label]);

void main() {
  late _Source source;
  late MatchmakerExploreRepositoryImpl repository;

  setUp(() {
    source = _Source();
    repository = MatchmakerExploreRepositoryImpl(source);
  });

  test('every open asks the server again', () async {
    await repository.getFilters();
    await repository.getFilters();
    expect(source.calls, 2);
  });

  test('a question the dashboard adds shows on the next open', () async {
    expect(_labels(await repository.getFilters()), ['العمر']);
    source.labels = ['العمر', 'الجنسية'];
    expect(_labels(await repository.getFilters()), ['العمر', 'الجنسية']);
  });

  test('two asks at the same moment share one request', () async {
    source.gate = Completer<void>();
    final first = repository.getFilters();
    final second = repository.getFilters();
    source.gate!.complete();
    await Future.wait([first, second]);
    expect(source.calls, 1);
  });

  test('a failed fetch is followed by a fresh one', () async {
    source.fail = true;
    expect((await repository.getFilters()).isLeft(), isTrue);
    source.fail = false;
    expect(_labels(await repository.getFilters()), ['العمر']);
    expect(source.calls, 2);
  });
}
