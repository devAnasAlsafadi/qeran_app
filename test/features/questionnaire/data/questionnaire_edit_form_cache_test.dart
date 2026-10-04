import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/features/questionnaire/data/datasources/questionnaire_remote_datasource.dart';
import 'package:qeran/features/questionnaire/data/models/editable_category_model.dart';
import 'package:qeran/features/questionnaire/data/repositories/questionnaire_repository_impl.dart';

class _MockDataSource extends Mock implements QuestionnaireRemoteDataSource {}

EditableCategoryModel _category(String name) => EditableCategoryModel(
  categoryId: 1,
  categoryName: name,
  questions: const [],
);

/// The edit form carries the member's own answers, so it is read once per
/// account — never served to the next account on the phone.
void main() {
  late _MockDataSource dataSource;
  late QuestionnaireRepositoryImpl repo;

  setUp(() {
    dataSource = _MockDataSource();
    repo = QuestionnaireRepositoryImpl(dataSource);
  });

  Future<String> firstCategory() async => (await repo.fetchEditForm()).fold(
    (failure) => 'failed: ${failure.message}',
    (form) => form.single.categoryName,
  );

  test('read once for the account, then served from memory', () async {
    when(
      () => dataSource.fetchEditForm(),
    ).thenAnswer((_) async => [_category('A')]);

    await firstCategory();
    await firstCategory();

    verify(() => dataSource.fetchEditForm()).called(1);
  });

  test('the account changes: the next one reads its own answers', () async {
    when(
      () => dataSource.fetchEditForm(),
    ).thenAnswer((_) async => [_category('A')]);
    await firstCategory();

    repo.forgetAccount();
    when(
      () => dataSource.fetchEditForm(),
    ).thenAnswer((_) async => [_category('B')]);

    expect(await firstCategory(), 'B');
  });

  test('a read in flight for the previous account is not kept', () async {
    final previous = Completer<List<EditableCategoryModel>>();
    when(() => dataSource.fetchEditForm()).thenAnswer((_) => previous.future);
    final stale = repo.fetchEditForm();

    repo.forgetAccount();
    previous.complete([_category('A')]);
    await stale;
    when(
      () => dataSource.fetchEditForm(),
    ).thenAnswer((_) async => [_category('B')]);

    expect(await firstCategory(), 'B');
  });
}
