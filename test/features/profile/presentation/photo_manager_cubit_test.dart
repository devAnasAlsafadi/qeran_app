import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/profile/domain/entities/photo_slot.dart';
import 'package:qeran/features/profile/domain/entities/profile_image.dart';
import 'package:qeran/features/profile/domain/usecases/add_profile_images_usecase.dart';
import 'package:qeran/features/profile/domain/usecases/delete_profile_image_usecase.dart';
import 'package:qeran/features/profile/domain/usecases/get_profile_images_usecase.dart';
import 'package:qeran/features/profile/domain/usecases/set_main_profile_image_usecase.dart';
import 'package:qeran/features/profile/presentation/blocs/photo_manager/photo_manager_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/photo_manager/photo_manager_state.dart';

class _MockGet extends Mock implements GetProfileImagesUseCase {}

class _MockAdd extends Mock implements AddProfileImagesUseCase {}

class _MockDelete extends Mock implements DeleteProfileImageUseCase {}

class _MockSetMain extends Mock implements SetMainProfileImageUseCase {}

class _MockPrefs extends Mock implements SharedPrefService {}

OwnerImage _img(String id, {bool main = false}) =>
    OwnerImage(id: id, url: 'https://cdn.test/$id.jpg', isProfile: main);

void main() {
  late _MockGet getImages;
  late _MockAdd addImages;
  late _MockDelete deleteImage;
  late _MockSetMain setMain;
  late _MockPrefs prefs;

  // Each test owns a private directory so file creation in one case can
  // never race the cleanup of another — the failure mode that makes
  // temp-file tests flaky on Windows.
  late Directory tempDir;
  var caseCounter = 0;

  setUpAll(() {
    registerFallbackValue(<File>[]);
  });

  setUp(() {
    getImages = _MockGet();
    addImages = _MockAdd();
    deleteImage = _MockDelete();
    setMain = _MockSetMain();
    prefs = _MockPrefs();
    caseCounter++;
    tempDir = Directory.systemTemp.createTempSync('photo_mgr_${caseCounter}_');
    when(
      () => prefs.save(StorageKeys.uploadedPhotos, true),
    ).thenAnswer((_) async => true);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// Creates a real, valid-looking jpg inside this test's own directory.
  String makePhoto(String name) {
    final file = File('${tempDir.path}${Platform.pathSeparator}$name.jpg')
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.filled(64, 7));
    return file.path;
  }

  PhotoManagerCubit build({
    PhotoManagerMode mode = PhotoManagerMode.profileEdit,
  }) => PhotoManagerCubit(
    mode: mode,
    getImages: getImages,
    addImages: addImages,
    deleteImage: deleteImage,
    setMain: setMain,
    sharedPrefs: prefs,
  );

  void stubServerImages(List<OwnerImage> images) {
    when(() => getImages()).thenAnswer((_) async => Right(images));
  }

  group('staging local files', () {
    test('adds a picked file without touching the network', () async {
      stubServerImages([]);
      final cubit = build();
      await cubit.load();

      cubit.addImage(makePhoto('a'));

      expect(cubit.state.stagedPaths, hasLength(1));
      expect(cubit.state.slots.single, isA<StagedPhotoSlot>());
      verifyNever(() => addImages(any()));
      await cubit.close();
    });

    test('the first photo of an empty profile becomes main', () async {
      stubServerImages([]);
      final cubit = build();
      await cubit.load();

      final first = makePhoto('a');
      cubit.addImage(first);
      cubit.addImage(makePhoto('b'));

      expect(cubit.state.stagedMainPath, first);
      expect(cubit.state.slots.first.isMain, isTrue);
      await cubit.close();
    });

    test('rejects a file whose extension is not an image', () async {
      stubServerImages([]);
      final cubit = build();
      await cubit.load();
      final bad = File('${tempDir.path}${Platform.pathSeparator}note.txt')
        ..createSync();

      cubit.addImage(bad.path);

      expect(cubit.state.stagedPaths, isEmpty);
      expect(cubit.state.event, PhotoManagerEvent.validationFailure);
      await cubit.close();
    });
  });

  group('the five-photo cap counts server and staged together', () {
    test('three server plus two staged rejects a sixth', () async {
      stubServerImages([_img('s1'), _img('s2'), _img('s3')]);
      final cubit = build();
      await cubit.load();

      cubit.addImage(makePhoto('a'));
      cubit.addImage(makePhoto('b'));
      expect(cubit.state.totalCount, 5);
      expect(cubit.state.canAddMore, isFalse);

      cubit.addImage(makePhoto('c'));

      expect(cubit.state.totalCount, 5, reason: 'sixth must be refused');
      expect(cubit.state.stagedPaths, hasLength(2));
      expect(cubit.state.event, PhotoManagerEvent.maxReached);
      await cubit.close();
    });

    test('five staged and no server photos also rejects a sixth', () async {
      stubServerImages([]);
      final cubit = build();
      await cubit.load();

      for (final n in ['a', 'b', 'c', 'd', 'e']) {
        cubit.addImage(makePhoto(n));
      }
      expect(cubit.state.totalCount, 5);

      cubit.addImage(makePhoto('f'));

      expect(cubit.state.stagedPaths, hasLength(5));
      expect(cubit.state.event, PhotoManagerEvent.maxReached);
      await cubit.close();
    });

    test('five server photos alone rejects any staging', () async {
      stubServerImages([
        _img('s1'),
        _img('s2'),
        _img('s3'),
        _img('s4'),
        _img('s5'),
      ]);
      final cubit = build();
      await cubit.load();

      cubit.addImage(makePhoto('a'));

      expect(cubit.state.stagedPaths, isEmpty);
      expect(cubit.state.event, PhotoManagerEvent.maxReached);
      await cubit.close();
    });
  });

  group('deleting', () {
    test('deleting a server image calls the API and refreshes', () async {
      stubServerImages([_img('s1', main: true), _img('s2')]);
      when(() => deleteImage('s2')).thenAnswer((_) async => const Right(unit));
      final cubit = build();
      await cubit.load();

      await cubit.deleteServerImage('s2');

      verify(() => deleteImage('s2')).called(1);
      expect(cubit.state.event, PhotoManagerEvent.deleted);
      await cubit.close();
    });

    test('dropping a staged file issues no request', () async {
      stubServerImages([]);
      final cubit = build();
      await cubit.load();
      final a = makePhoto('a');
      final b = makePhoto('b');
      cubit.addImage(a);
      cubit.addImage(b);

      cubit.removeStaged(a);

      expect(cubit.state.stagedPaths, [b]);
      verifyNever(() => deleteImage(any()));
      // 'a' was main; with no server main, 'b' inherits it.
      expect(cubit.state.stagedMainPath, b);
      await cubit.close();
    });
  });

  group('set main across mixed slots', () {
    test(
      'three server photos, two staged, staged one set as main: reorders '
      'locally, issues no PUT, then becomes server-main after upload',
      () async {
        final before = [_img('s1', main: true), _img('s2'), _img('s3')];
        stubServerImages(before);
        final cubit = build();
        await cubit.load();

        final a = makePhoto('a');
        final b = makePhoto('b');
        cubit.addImage(a);
        cubit.addImage(b);
        expect(cubit.state.totalCount, 5);

        // Promote the SECOND staged photo — not the first, so a correct
        // implementation cannot pass by accident.
        final stagedB = cubit.state.slots.last;
        expect(stagedB, isA<StagedPhotoSlot>());
        await cubit.setMain(stagedB);

        // Local only: no PUT yet, and the server's main is untouched.
        verifyNever(() => setMain(any()));
        expect(cubit.state.stagedMainPath, b);
        expect(cubit.state.event, PhotoManagerEvent.mainChanged);

        // The upload must send the chosen photo FIRST.
        late List<File> sent;
        when(() => addImages(any())).thenAnswer((invocation) async {
          sent = invocation.positionalArguments.first as List<File>;
          return const Right(unit);
        });
        // After upload the server reports the two new photos; 'n1' is the
        // one that went up at index 0.
        final after = [...before, _img('n1'), _img('n2')];
        stubServerImages(after);
        when(() => setMain('n1')).thenAnswer((_) async => const Right(unit));

        await cubit.upload();

        expect(
          sent.map((f) => f.path).toList(),
          [b, a],
          reason: 'the chosen main photo must be uploaded first',
        );
        verify(() => setMain('n1')).called(1);
        expect(cubit.state.stagedPaths, isEmpty);
        expect(cubit.state.stagedMainPath, isNull);
        await cubit.close();
      },
    );

    test('setting main on a server photo calls the API', () async {
      stubServerImages([_img('s1', main: true), _img('s2')]);
      when(() => setMain('s2')).thenAnswer((_) async => const Right(unit));
      final cubit = build();
      await cubit.load();

      await cubit.setMain(ServerPhotoSlot(_img('s2')));

      verify(() => setMain('s2')).called(1);
      expect(cubit.state.event, PhotoManagerEvent.mainChanged);
      await cubit.close();
    });

    test('set-main moves the badge without reshuffling the grid', () async {
      // The server sorts IsProfile DESC, CreatedAt DESC, Id — so the refetch
      // that follows a successful set-main comes back with the PROMOTED photo
      // first. Rendering that order would teleport the tapped tile to slot 0,
      // which is what made the badge look like it never moved. Positions are
      // pinned to id; only isMain is allowed to travel.
      stubServerImages([_img('a1', main: true), _img('b2')]);
      final cubit = build();
      await cubit.load();
      expect(
        cubit.state.slots.cast<ServerPhotoSlot>().map((s) => s.id),
        ['a1', 'b2'],
      );

      when(() => setMain('b2')).thenAnswer((_) async => const Right(unit));
      // The refetch payload exactly as the server orders it: new main leads.
      stubServerImages([_img('b2', main: true), _img('a1')]);

      await cubit.setMain(ServerPhotoSlot(_img('b2')));

      final slots = cubit.state.slots.cast<ServerPhotoSlot>();
      expect(
        slots.map((s) => s.id),
        ['a1', 'b2'],
        reason: 'tiles must hold position across a mutation',
      );
      expect(
        slots.where((s) => s.isMain).map((s) => s.id),
        ['b2'],
        reason: 'exactly one main, and it is the tapped photo',
      );
      await cubit.close();
    });
    test('an empty profile needs no promotion call after upload', () async {
      stubServerImages([]);
      when(() => addImages(any())).thenAnswer((_) async => const Right(unit));
      final cubit = build();
      await cubit.load();
      cubit.addImage(makePhoto('a'));

      stubServerImages([_img('n1', main: true)]);
      await cubit.upload();

      // With no pre-existing photos the backend takes index 0 as main, so
      // spending an extra request would be wrong.
      verifyNever(() => setMain(any()));
      await cubit.close();
    });
  });

  group('batch upload', () {
    test('sends every staged file in one request and clears them', () async {
      stubServerImages([]);
      final cubit = build();
      await cubit.load();
      final a = makePhoto('a');
      final b = makePhoto('b');
      cubit.addImage(a);
      cubit.addImage(b);

      late List<File> sent;
      when(() => addImages(any())).thenAnswer((invocation) async {
        sent = invocation.positionalArguments.first as List<File>;
        return const Right(unit);
      });
      stubServerImages([_img('n1', main: true), _img('n2')]);

      await cubit.upload();

      verify(() => addImages(any())).called(1);
      expect(sent.map((f) => f.path), containsAll([a, b]));
      expect(cubit.state.stagedPaths, isEmpty);
      expect(cubit.state.serverImages, hasLength(2));
      await cubit.close();
    });

    test('a failed upload keeps the staged files for retry', () async {
      stubServerImages([]);
      final cubit = build();
      await cubit.load();
      final a = makePhoto('a');
      final b = makePhoto('b');
      cubit.addImage(a);
      cubit.addImage(b);

      when(() => addImages(any())).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'errors.upload_failed')),
      );

      await cubit.upload();

      expect(
        cubit.state.stagedPaths,
        [a, b],
        reason: 'staged files must survive so the user can retry',
      );
      expect(cubit.state.event, PhotoManagerEvent.actionFailure);
      expect(cubit.state.errorMessage, 'errors.upload_failed');
      expect(cubit.state.isBusy, isFalse);
      await cubit.close();
    });

    test('upload marks the onboarding step as finished', () async {
      stubServerImages([]);
      when(() => addImages(any())).thenAnswer((_) async => const Right(unit));
      final cubit = build(mode: PhotoManagerMode.onboarding);
      await cubit.load();
      cubit.addImage(makePhoto('a'));

      stubServerImages([_img('n1', main: true)]);
      await cubit.upload();

      expect(cubit.state.event, PhotoManagerEvent.finished);
      verify(() => prefs.save(StorageKeys.uploadedPhotos, true)).called(1);
      await cubit.close();
    });
  });

  group('skip', () {
    test('onboarding skip persists the flag and finishes', () async {
      stubServerImages([]);
      final cubit = build(mode: PhotoManagerMode.onboarding);
      await cubit.load();

      await cubit.skip();

      verify(() => prefs.save(StorageKeys.uploadedPhotos, true)).called(1);
      expect(cubit.state.event, PhotoManagerEvent.finished);
      await cubit.close();
    });

    test('skip is unavailable in profile edit', () async {
      stubServerImages([]);
      final cubit = build();
      await cubit.load();

      await cubit.skip();

      verifyNever(() => prefs.save(StorageKeys.uploadedPhotos, true));
      expect(cubit.state.event, isNot(PhotoManagerEvent.finished));
      await cubit.close();
    });
  });
}
