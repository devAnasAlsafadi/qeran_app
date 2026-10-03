import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/comment_submit_outcome.dart';
import 'package:qeran/features/community/domain/entities/community_config.dart';
import 'package:qeran/features/community/domain/usecases/get_community_config_usecase.dart';
import 'package:qeran/features/community/presentation/blocs/composer/community_composer_cubit.dart';

class _MockGetConfig extends Mock implements GetCommunityConfigUseCase {}

/// A composer over a config with [maxLength], and sends that record what
/// went and answer [answer].
class ComposerHarness {
  ComposerHarness({
    int? maxLength = 500,
    bool configFails = false,
    Duration cooldown = const Duration(seconds: 30),
  }) {
    when(() => getConfig()).thenAnswer(
      (_) async => configFails
          ? const Left(OfflineFailure())
          : Right(CommunityConfig(commentMaxLength: maxLength)),
    );
    cubit = CommunityComposerCubit(
      getConfig: getConfig,
      send: _send,
      retry: _retry,
      defaultCooldown: cooldown,
    );
  }

  final getConfig = _MockGetConfig();
  late final CommunityComposerCubit cubit;

  /// What a send or a retry answers next.
  CommentSubmitOutcome? answer;

  /// Each send: its text and the comment it answers.
  final sent = <(String, int?)>[];
  final retried = <int>[];

  Future<CommentSubmitOutcome?> _send(String text, {int? parentId}) async {
    sent.add((text, parentId));
    return answer;
  }

  Future<CommentSubmitOutcome?> _retry(int localId) async {
    retried.add(localId);
    return answer;
  }

  Future<void> dispose() => cubit.close();
}
