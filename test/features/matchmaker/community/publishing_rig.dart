import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/community_config.dart';
import 'package:qeran/features/community/domain/entities/media_upload_outcome.dart';

import 'composer_rig.dart';

/// Her composer with images on: the limits, and `a.jpg` in her gallery.
ComposerHarness imageComposer() {
  final h = ComposerHarness()
    ..configure(
      const CommunityConfig(
        postTextMaxLength: 2000,
        maxImagesPerPost: 10,
        maxImageSizeBytes: 5242880,
      ),
    );
  h.picker.gallery = ['a.jpg'];
  return h;
}

/// The loader in the strip never settles: frames, not pumpAndSettle.
Future<void> frames(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 400));

/// The upload reports half, then waits for the answer — or her cancel.
Completer<Either<Failure, MediaUploadOutcome<String>>> holdUpload(
  ComposerHarness h,
) {
  final answer = Completer<Either<Failure, MediaUploadOutcome<String>>>();
  when(
    () => h.publishing.repository.uploadImage(
      any(),
      onProgress: any(named: 'onProgress'),
      cancel: any(named: 'cancel'),
    ),
  ).thenAnswer((call) {
    (call.namedArguments[#onProgress] as UploadProgress)(50, 100);
    final cancel = call.namedArguments[#cancel] as UploadCancel;
    cancel.whenCancelled.then((_) {
      if (!answer.isCompleted) {
        answer.complete(const Left(UploadCancelledFailure()));
      }
    });
    return answer.future;
  });
  return answer;
}

/// Opens the composer, types, adds `a.jpg` from the gallery and taps
/// Publish — with the labels of [locale].
Future<void> publishWithImage(
  WidgetTester tester,
  ComposerHarness h, {
  Locale locale = const Locale('en'),
}) async {
  final ar = locale.languageCode == 'ar';
  await startComposer(tester, h, locale: locale);
  await tester.enterText(find.byType(TextField), 'إرشاد');
  await tester.tap(find.text(ar ? 'صور' : 'Images').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(ar ? 'اختيار من المعرض' : 'Choose from gallery'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(ar ? 'نشر' : 'Publish'));
  await frames(tester);
}
