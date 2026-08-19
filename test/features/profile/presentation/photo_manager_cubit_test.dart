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
import 'package:qeran/generated/locale_keys.g.dart';

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

  /// Writes [bytes] to [fileName] inside this test's own directory. The name
  /// carries its own extension — validation reads CONTENT, so the two can be
  /// made to disagree on purpose.
  String makeFile(String fileName, List<int> bytes) {
    final file = File('${tempDir.path}${Platform.pathSeparator}$fileName')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
    return file.path;
  }

  /// Leading bytes of each format the sniffer knows, plus two it must refuse.
  const jpeg = [0xFF, 0xD8, 0xFF, 0xE0];
  const png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  const pdf = [0x25, 0x50, 0x44, 0x46]; // '%PDF'
  // Box length, then 'ftypheic' — a genuine HEIC, not a renamed JPEG.
  const heic = [
    0x00, 0x00, 0x00, 0x18,
    0x66, 0x74, 0x79, 0x70,
    0x68, 0x65, 0x69, 0x63,
  ];

  /// A real, valid-looking jpg — correct signature, then filler.
  String makePhoto(String name) =>
      makeFile('$name.jpg', [...jpeg, ...List<int>.filled(60, 7)]);

  /// Same, at an exact byte length — for the size gate's boundary. Keeps the
  /// JPEG signature so only SIZE can be what fails.
  String makeSizedPhoto(String name, int bytes) =>
      makeFile('$name.jpg', [...jpeg, ...List<int>.filled(bytes - jpeg.length, 7)]);

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

  // Type is decided by the file's leading bytes, never by its name. See
  // `_hasSupportedSignature` for why the extension is not evidence.
  group('type validation reads content, not the filename', () {
    Future<PhotoManagerCubit> loaded() async {
      stubServerImages([]);
      final cubit = build();
      await cubit.load();
      return cubit;
    }

    void expectRejectedAsType(PhotoManagerCubit cubit) {
      expect(cubit.state.stagedPaths, isEmpty);
      expect(cubit.state.event, PhotoManagerEvent.validationFailure);
      expect(
        cubit.state.errorMessage,
        LocaleKeys.profile_photos_validation_type,
      );
    }

    test('a real JPEG is accepted', () async {
      final cubit = await loaded();

      cubit.addImage(makeFile('a.jpg', jpeg));

      expect(cubit.state.stagedPaths, hasLength(1));
      await cubit.close();
    });

    test('a real PNG is accepted', () async {
      final cubit = await loaded();

      cubit.addImage(makeFile('a.png', png));

      expect(cubit.state.stagedPaths, hasLength(1));
      await cubit.close();
    });

    test('a PDF renamed .jpg is rejected', () async {
      final cubit = await loaded();

      cubit.addImage(makeFile('sneaky.jpg', pdf));

      expectRejectedAsType(cubit);
      await cubit.close();
    });

    test('a genuine HEIC is rejected whatever it is called', () async {
      final cubit = await loaded();

      cubit.addImage(makeFile('photo.heic', heic));

      expectRejectedAsType(cubit);
      await cubit.close();
    });

    // The payoff for sniffing over blocklisting: Android's picker re-encodes
    // to JPEG but keeps the original name, so this file is a valid photo the
    // backend accepts. An extension check would have refused it.
    test('JPEG bytes under a .heic name are accepted', () async {
      final cubit = await loaded();

      cubit.addImage(makeFile('scaled_x.heic', jpeg));

      expect(cubit.state.stagedPaths, hasLength(1));
      await cubit.close();
    });

    test('an empty file is rejected — too short to match any signature',
        () async {
      final cubit = await loaded();

      cubit.addImage(makeFile('empty.jpg', const []));

      expectRejectedAsType(cubit);
      await cubit.close();
    });

    test('a file truncated mid-signature is rejected', () async {
      final cubit = await loaded();

      cubit.addImage(makeFile('cut.jpg', const [0xFF, 0xD8]));

      expectRejectedAsType(cubit);
      await cubit.close();
    });

    // The gate is 5 MB — the server's own limit (Tariq). It used to be 2 MB,
    // which rejected photos the backend would have taken.
    test('rejects a file over the 5 MB ceiling', () async {
      stubServerImages([]);
      final cubit = build();
      await cubit.load();

      cubit.addImage(makeSizedPhoto('huge', 5 * 1024 * 1024 + 1));

      expect(cubit.state.stagedPaths, isEmpty);
      expect(cubit.state.event, PhotoManagerEvent.validationFailure);
      expect(
        cubit.state.errorMessage,
        LocaleKeys.auth_photo_validation_size,
      );
      await cubit.close();
    });

    test('accepts a file sitting exactly on the 5 MB ceiling', () async {
      stubServerImages([]);
      final cubit = build();
      await cubit.load();

      cubit.addImage(makeSizedPhoto('exact', 5 * 1024 * 1024));

      expect(cubit.state.stagedPaths, hasLength(1));
      expect(cubit.state.event, isNot(PhotoManagerEvent.validationFailure));
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
      'with server photos present, promoting a staged one uploads it and '
      'sets it main in a single action',
      () async {
        // BUG 4: this used to record a local-only flag, leaving the server's
        // main badge standing alongside the staged one — two photos claiming
        // to be main, one of which did not exist yet.
        final before = [_img('s1', main: true), _img('s2')];
        stubServerImages(before);
        final cubit = build();
        await cubit.load();

        final a = makePhoto('a');
        final b = makePhoto('b');
        cubit.addImage(a);
        cubit.addImage(b);

        late List<File> sent;
        when(() => addImages(any())).thenAnswer((invocation) async {
          sent = invocation.positionalArguments.first as List<File>;
          return Right(<OwnerImage>[_img('new1')]);
        });
        when(() => setMain('new1')).thenAnswer((_) async => const Right(unit));
        stubServerImages([_img('new1', main: true), _img('s1'), _img('s2')]);

        final stagedB = cubit.state.slots.last as StagedPhotoSlot;
        expect(stagedB.path, b);
        await cubit.setMain(stagedB);

        expect(
          sent.map((f) => f.path).toList(),
          [b],
          reason: 'only the tapped photo goes up, not the whole staging area',
        );
        // The id comes from the POST response, so no diffing and no second
        // set-main from the batch path.
        verify(() => setMain('new1')).called(1);
        verifyNever(() => setMain('s1'));

        final mains = cubit.state.slots
            .whereType<ServerPhotoSlot>()
            .where((s) => s.isMain)
            .map((s) => s.id);
        expect(mains, ['new1'], reason: 'exactly one main, and it is the new one');
        expect(
          cubit.state.stagedPaths,
          [a],
          reason: 'the other staged photo is untouched and still awaits upload',
        );
        expect(cubit.state.event, PhotoManagerEvent.mainChanged);
        await cubit.close();
      },
    );

    test(
      'with an empty profile, promoting a staged photo stays local until '
      'the batch upload',
      () async {
        // Registration: nothing is on the server, so there is no rival main
        // to diverge from and `_mainFirst` still carries the choice.
        stubServerImages([]);
        final cubit = build();
        await cubit.load();
        final a = makePhoto('a');
        final b = makePhoto('b');
        cubit.addImage(a);
        cubit.addImage(b);

        await cubit.setMain(cubit.state.slots.last);

        verifyNever(() => addImages(any()));
        verifyNever(() => setMain(any()));
        expect(cubit.state.stagedMainPath, b);
        expect(cubit.state.stagedPaths, [a, b]);
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
      when(() => addImages(any())).thenAnswer(
        (_) async => const Right(<OwnerImage>[]),
      );
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

  group('atomic promote: upload one staged photo and make it main', () {
    /// Puts the cubit in the only state that routes a staged tap to the
    /// atomic path: server photos already exist, so a local-only main flag
    /// would leave two photos wearing the badge.
    Future<(PhotoManagerCubit, String)> withStagedPhoto() async {
      stubServerImages([_img('s1', main: true), _img('s2')]);
      final cubit = build();
      await cubit.load();
      final path = makePhoto('picked');
      cubit.addImage(path);
      return (cubit, path);
    }

    test('success: the new photo lands as the one and only main', () async {
      final (cubit, _) = await withStagedPhoto();
      when(
        () => addImages(any()),
      ).thenAnswer((_) async => Right(<OwnerImage>[_img('fresh')]));
      when(() => setMain('fresh')).thenAnswer((_) async => const Right(unit));
      stubServerImages([_img('fresh', main: true), _img('s1'), _img('s2')]);

      await cubit.setMain(cubit.state.slots.last);

      verify(() => setMain('fresh')).called(1);
      final mains = cubit.state.serverImages
          .where((i) => i.isProfile)
          .map((i) => i.id);
      expect(mains, ['fresh']);
      expect(
        cubit.state.stagedPaths,
        isEmpty,
        reason: 'it lives on the server now',
      );
      expect(cubit.state.inFlightPhotoIds, isEmpty);
      expect(cubit.state.isBusy, isFalse);
      expect(cubit.state.event, PhotoManagerEvent.mainChanged);
      await cubit.close();
    });

    test('upload fails: nothing reaches the server, the file stays staged', () async {
      final (cubit, path) = await withStagedPhoto();
      when(() => addImages(any())).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'boom')),
      );

      await cubit.setMain(cubit.state.slots.last);

      verifyNever(() => setMain(any()));
      expect(
        cubit.state.stagedPaths,
        [path],
        reason: 'the file never left the device, so a retry costs nothing',
      );
      expect(
        cubit.state.serverImages.map((i) => i.id),
        ['s1', 's2'],
        reason: 'server state untouched',
      );
      expect(cubit.state.inFlightPhotoIds, isEmpty);
      expect(cubit.state.event, PhotoManagerEvent.actionFailure);
      expect(cubit.state.errorMessage, 'boom');
      await cubit.close();
    });

    test('set-main fails after upload: photo is server-side but not main', () async {
      final (cubit, _) = await withStagedPhoto();
      when(
        () => addImages(any()),
      ).thenAnswer((_) async => Right(<OwnerImage>[_img('fresh')]));
      when(() => setMain('fresh')).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'not main')),
      );
      // The upload DID land, so the refreshed list carries it — unpromoted.
      stubServerImages([_img('s1', main: true), _img('s2'), _img('fresh')]);

      await cubit.setMain(cubit.state.slots.last);

      expect(
        cubit.state.serverImages.map((i) => i.id),
        contains('fresh'),
        reason: 'no rollback — the photo genuinely exists now',
      );
      expect(
        cubit.state.serverImages.where((i) => i.isProfile).map((i) => i.id),
        ['s1'],
        reason: 'the old main keeps the badge; the promotion is what failed',
      );
      expect(cubit.state.stagedPaths, isEmpty);
      expect(cubit.state.inFlightPhotoIds, isEmpty);
      expect(cubit.state.event, PhotoManagerEvent.actionFailure);
      expect(cubit.state.errorMessage, 'not main');
      await cubit.close();
    });
  });

  group('in-flight tracking', () {
    test('set-main claims and releases the photo id', () async {
      stubServerImages([_img('s1', main: true), _img('s2')]);
      final cubit = build();
      await cubit.load();
      final seen = <Set<String>>[];
      final sub = cubit.stream.listen((s) => seen.add(s.inFlightPhotoIds));
      when(() => setMain('s2')).thenAnswer((_) async => const Right(unit));

      await cubit.setMain(ServerPhotoSlot(_img('s2')));
      await sub.cancel();

      expect(
        seen.any((ids) => ids.contains('s2')),
        isTrue,
        reason: 'the tile has to light up while the request runs',
      );
      expect(cubit.state.inFlightPhotoIds, isEmpty);
      await cubit.close();
    });

    test('delete claims and releases, even when the request fails', () async {
      stubServerImages([_img('s1', main: true), _img('s2')]);
      final cubit = build();
      await cubit.load();
      final seen = <Set<String>>[];
      final sub = cubit.stream.listen((s) => seen.add(s.inFlightPhotoIds));
      when(() => deleteImage('s2')).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'nope')),
      );

      await cubit.deleteServerImage('s2');
      await sub.cancel();

      expect(seen.any((ids) => ids.contains('s2')), isTrue);
      expect(
        cubit.state.inFlightPhotoIds,
        isEmpty,
        reason: 'released in a finally, so a failure cannot strand the tile',
      );
      await cubit.close();
    });

    test('the batch upload claims no ids — it lights every staged tile', () async {
      stubServerImages([]);
      final cubit = build();
      await cubit.load();
      cubit.addImage(makePhoto('a'));
      cubit.addImage(makePhoto('b'));
      final seen = <Set<String>>[];
      final actions = <PhotoManagerAction?>[];
      final sub = cubit.stream.listen((s) {
        seen.add(s.inFlightPhotoIds);
        actions.add(s.inFlight);
      });
      when(
        () => addImages(any()),
      ).thenAnswer((_) async => const Right(<OwnerImage>[]));

      await cubit.upload();
      await sub.cancel();

      expect(
        seen.every((ids) => ids.isEmpty),
        isTrue,
        reason: 'the batch owns the whole staging area, not one photo',
      );
      expect(actions, contains(PhotoManagerAction.upload));
      await cubit.close();
    });
  });

  group('isSlotLoading', () {
    final server = ServerPhotoSlot(_img('s1'));
    const staged = StagedPhotoSlot(path: '/tmp/a.jpg', isMain: false);
    const idle = PhotoManagerState(mode: PhotoManagerMode.profileEdit);

    test('a server slot lights up only for its own id', () {
      final other = idle.copyWith(
        inFlight: PhotoManagerAction.setMain,
        inFlightPhotoIds: const {'other'},
      );
      expect(other.isSlotLoading(server), isFalse);
      expect(
        other.copyWith(inFlightPhotoIds: const {'s1'}).isSlotLoading(server),
        isTrue,
      );
    });

    test('a staged slot lights up for the batch, or for its own path', () {
      // Two ways in: the batch takes every staged file, and the atomic
      // promotion takes exactly one, tracked by path.
      expect(
        idle.copyWith(inFlight: PhotoManagerAction.upload).isSlotLoading(staged),
        isTrue,
      );
      expect(
        idle
            .copyWith(
              inFlight: PhotoManagerAction.promoteStaged,
              inFlightPhotoIds: const {'/tmp/a.jpg'},
            )
            .isSlotLoading(staged),
        isTrue,
      );
      expect(
        idle
            .copyWith(
              inFlight: PhotoManagerAction.promoteStaged,
              inFlightPhotoIds: const {'/tmp/other.jpg'},
            )
            .isSlotLoading(staged),
        isFalse,
        reason: 'a sibling being promoted must not dim this one',
      );
    });

    test('nothing loads while idle', () {
      expect(idle.isSlotLoading(server), isFalse);
      expect(idle.isSlotLoading(staged), isFalse);
    });
  });

  // The backend refuses to delete a profile's only photo (`IMAGE_LAST_ONE`),
  // so the control is withheld rather than left to produce a guaranteed error.
  group('canRemove', () {
    PhotoManagerState stateWith(List<OwnerImage> images) => PhotoManagerState(
      mode: PhotoManagerMode.profileEdit,
      serverImages: images,
    );

    test('the only server photo may not be removed', () {
      final state = stateWith([_img('s1')]);

      expect(state.canRemove(ServerPhotoSlot(_img('s1'))), isFalse);
    });

    test('either of two server photos may be removed', () {
      final state = stateWith([_img('s1'), _img('s2')]);

      expect(state.canRemove(ServerPhotoSlot(_img('s1'))), isTrue);
      expect(state.canRemove(ServerPhotoSlot(_img('s2'))), isTrue);
    });

    // Staged files never reached the server, so dropping one cannot leave the
    // profile photoless — the lone SERVER photo is still there either way.
    test('a staged file is always removable, even beside a lone server photo',
        () {
      final state = stateWith([_img('s1')]);

      expect(
        state.canRemove(
          const StagedPhotoSlot(path: '/tmp/a.jpg', isMain: false),
        ),
        isTrue,
      );
    });

    // Corollary of the above: staging does NOT unlock the last server photo.
    test('staged photos do not count towards the one that must remain', () {
      final state = PhotoManagerState(
        mode: PhotoManagerMode.profileEdit,
        serverImages: [_img('s1')],
        stagedPaths: const ['/tmp/a.jpg', '/tmp/b.jpg'],
      );

      expect(state.canRemove(ServerPhotoSlot(_img('s1'))), isFalse);
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
        return const Right(<OwnerImage>[]);
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
      when(() => addImages(any())).thenAnswer(
        (_) async => const Right(<OwnerImage>[]),
      );
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
