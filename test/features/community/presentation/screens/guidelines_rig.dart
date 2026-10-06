import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/data/datasources/mock/community_mock_documents.dart';
import 'package:qeran/features/community/data/models/community_guidelines_model.dart';
import 'package:qeran/features/community/domain/entities/community_guidelines.dart';
import 'package:qeran/features/community/domain/entities/guidelines_acceptance.dart';
import 'package:qeran/features/community/domain/usecases/accept_community_guidelines_usecase.dart';
import 'package:qeran/features/community/domain/usecases/get_community_guidelines_usecase.dart';
import 'package:qeran/features/community/presentation/blocs/guidelines/community_guidelines_cubit.dart';
import 'package:qeran/features/community/presentation/screens/community_guidelines_page.dart';
import 'package:qeran/features/community/domain/entities/community_viewer.dart';

import 'pushed_step_rig.dart';

class _MockGet extends Mock implements GetCommunityGuidelinesUseCase {}

class _MockAccept extends Mock implements AcceptCommunityGuidelinesUseCase {}

/// The mock seed's text (the board's five rules) at [version], with
/// [introEn] in place of its English intro when given.
CommunityGuidelines seedGuidelines({int version = 1, String? introEn}) =>
    CommunityGuidelinesModel.fromJson({
      ...communityMockGuidelines(),
      'version': version,
      'introEn': ?introEn,
    }).toEntity();

/// The guidelines step's use cases, scripted, behind the container's
/// cubit — the one the page asks for. An agreement is counted, and passed
/// on to [onAccepted] (the app's profile gate, in the app).
class GuidelinesHarness {
  GuidelinesHarness({void Function()? onAccepted}) {
    reads([Right(seedGuidelines())]);
    sl.registerFactory<CommunityGuidelinesCubit>(
      () => CommunityGuidelinesCubit(
        getGuidelines: getGuidelines,
        accept: accept,
        onAccepted: () {
          acceptedCalls++;
          onAccepted?.call();
        },
      ),
    );
  }

  final getGuidelines = _MockGet();
  final accept = _MockAccept();
  int acceptedCalls = 0;

  /// What the step answered; null while it's open.
  bool? result;

  /// Each read answers with the next of [answers].
  void reads(List<Either<Failure, CommunityGuidelines>> answers) =>
      when(() => getGuidelines()).thenAnswer((_) async => answers.removeAt(0));

  /// Each agreement answers with the next of [answers].
  void accepts(List<Either<Failure, GuidelinesAcceptance>> answers) =>
      when(() => accept(any())).thenAnswer((_) async => answers.removeAt(0));

  Future<void> dispose() => sl.reset();
}

/// Opens the guidelines in [locale] on a phone [size] for [viewer], as the
/// composer will.
Future<void> openGuidelines(
  WidgetTester tester,
  GuidelinesHarness harness, {
  Locale locale = const Locale('en'),
  Size size = const Size(390, 900),
  CommunityViewer viewer = CommunityViewer.member,
}) => openPushedStep(
  tester,
  (context) async =>
      harness.result = await openCommunityGuidelines(context, viewer: viewer),
  locale: locale,
  size: size,
);
