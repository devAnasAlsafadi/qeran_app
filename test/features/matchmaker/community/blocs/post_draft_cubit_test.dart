import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/community_config.dart';
import 'package:qeran/features/community/domain/entities/media_refusal.dart';
import 'package:qeran/features/community/domain/usecases/get_community_config_usecase.dart';
import 'package:qeran/features/community/domain/usecases/inspect_picked_image_usecase.dart';
import 'package:qeran/features/matchmaker/community/presentation/blocs/composer/post_draft_cubit.dart';

import '../composer_media_fakes.dart';

class _MockConfig extends Mock implements GetCommunityConfigUseCase {}

void main() {
  late _MockConfig config;
  late FakeInspector inspector;
  late PostDraftCubit draft;
  setUp(() {
    config = _MockConfig();
    inspector = FakeInspector();
    draft = PostDraftCubit(
      getConfig: config,
      inspectImage: InspectPickedImageUseCase(inspector),
    );
  });
  tearDown(() => draft.close());

  Future<void> limits(CommunityConfig value) async {
    when(() => config(fresh: true)).thenAnswer((_) async => Right(value));
    await draft.loadConfig();
  }

  List<String> paths() => [for (final i in draft.state.images) i.path];

  test('the limits are read fresh on opening (K20)', () async {
    await limits(const CommunityConfig(postTextMaxLength: 2000));

    verify(() => config(fresh: true)).called(1);
    expect(draft.state.maxLength, 2000);
  });

  test('«نشر» needs text — counted after trimming — within the limit '
      '(C2, C7); images never stand in for it', () async {
    await limits(const CommunityConfig(postTextMaxLength: 5));

    draft.edit('   ');
    expect([draft.state.canPublish, draft.state.isEmpty], [false, true]);
    await draft.addImages(['a.jpg']);
    expect([draft.state.canPublish, draft.state.isEmpty], [false, false]);
    draft.edit('  abcde  ');
    expect([draft.state.length, draft.state.canPublish], [5, true]);
    draft.edit('abcdef');
    expect([draft.state.tooLong, draft.state.canPublish], [true, false]);
  });

  test('no limits read: the server checks length and count (S19)', () async {
    when(
      () => config(fresh: true),
    ).thenAnswer((_) async => const Left(OfflineFailure()));
    await draft.loadConfig();

    draft.edit(List.filled(3000, 'a').join());
    await draft.addImages([for (var i = 0; i < 12; i++) '$i.jpg']);

    expect(draft.state.canPublish, isTrue);
    expect(draft.state.freeImageSlots, isNull);
    expect(draft.state.images, hasLength(12));
  });

  test('a refusal stands until she edits the text (BA-A7)', () {
    draft.edit('رقم');
    draft.refused();
    expect(draft.state.rejected, isTrue);

    draft.edit('رقم ');
    expect(draft.state.rejected, isFalse);
  });

  test('images go in her order while they fit; more than fit: the first '
      'ones, and C8 names the post\'s limit', () async {
    await limits(const CommunityConfig(maxImagesPerPost: 3));
    await draft.addImages(['a.jpg']);
    expect(draft.state.notice, isNull);

    await draft.addImages(['b.jpg', 'c.jpg', 'd.jpg']);

    expect(paths(), ['a.jpg', 'b.jpg', 'c.jpg']);
    expect(
      draft.state.notice,
      const TooManyImages(added: 2, picked: 3, limit: 3),
    );
    expect(draft.state.imagesFull, isTrue);
  });

  test('a file the server wouldn\'t take stays out (C10), whether by its '
      'bytes or config\'s types', () async {
    await limits(const CommunityConfig(allowedImageTypes: ['png']));
    inspector.files['x.gif'] = null;

    await draft.addImages(['x.gif', 'a.jpg']);

    expect(draft.state.images, isEmpty);
    expect(draft.state.notice, const UnsupportedFile());
  });

  test(
    'over the size limit stays out (Q3); a danger notice wins over C8',
    () async {
      await limits(
        const CommunityConfig(maxImagesPerPost: 1, maxImageSizeBytes: 500),
      );
      inspector.files['big.jpg'] = jpeg('big.jpg', size: 900);

      await draft.addImages(['big.jpg', 'a.jpg', 'b.jpg']);

      expect(paths(), ['a.jpg']);
      expect(
        draft.state.notice,
        const ImageTooLarge(sizeBytes: 900, maxBytes: 500),
      );
    },
  );

  test('remove and reorder; a removal clears the notice', () async {
    await limits(const CommunityConfig(maxImagesPerPost: 2));
    await draft.addImages(['a.jpg', 'b.jpg', 'c.jpg']);

    draft.moveImage(1, 0);
    expect(paths(), ['b.jpg', 'a.jpg']);
    draft.removeImage(0);
    expect(paths(), ['a.jpg']);
    expect(draft.state.notice, isNull);
  });

  test('the server refused one: it leaves, and the notice says why', () async {
    await limits(const CommunityConfig(maxImageSizeBytes: 50));
    inspector.files['a.jpg'] = jpeg('a.jpg', size: 40);
    inspector.files['b.jpg'] = jpeg('b.jpg', size: 10);
    await draft.addImages(['a.jpg', 'b.jpg']);

    draft.imageRefused(path: 'a.jpg', refusal: MediaRefusal.tooLarge);
    expect(paths(), ['b.jpg']);
    expect(
      draft.state.notice,
      const ImageTooLarge(sizeBytes: 40, maxBytes: 50),
    );
  });

  test('the server refused one of a type it no longer takes: C10', () async {
    await draft.addImages(['a.jpg']);

    draft.imageRefused(path: 'a.jpg', refusal: MediaRefusal.invalidType);

    expect(draft.state.images, isEmpty);
    expect(draft.state.notice, const UnsupportedFile());
  });
}
