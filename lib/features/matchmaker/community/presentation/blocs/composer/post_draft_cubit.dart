import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/features/community/domain/entities/community_config.dart';
import 'package:qeran/features/community/domain/usecases/get_community_config_usecase.dart';

/// Her draft as it stands (C1, C2, C7, BA-A7).
class PostDraftState extends Equatable {
  const PostDraftState({this.text = '', this.config, this.rejected = false});

  final String text;

  /// The server's limits, read fresh when the composer opens (K20); null
  /// until then, or when they couldn't be read — the server checks then
  /// (S19).
  final CommunityConfig? config;

  /// The filter refused the text as it stands (BA-A7); gone once she edits.
  final bool rejected;

  int? get maxLength => config?.postTextMaxLength;

  /// UTF-16 code units after trimming, as the server counts (contract §6.2).
  int get length => text.trim().length;

  bool get tooLong => length > (maxLength ?? length);

  /// «نشر» turns on: some text, within the limit.
  bool get canPublish => length > 0 && !tooLong;

  /// Nothing to lose: × closes at once (C11).
  bool get isEmpty => length == 0;

  @override
  List<Object?> get props => [text, config, rejected];
}

/// Her draft (C1–C11): the text and the limits it's checked against.
class PostDraftCubit extends Cubit<PostDraftState>
    with SafeEmit<PostDraftState> {
  PostDraftCubit({required GetCommunityConfigUseCase getConfig})
    : _getConfig = getConfig,
      super(const PostDraftState());

  final GetCommunityConfigUseCase _getConfig;

  /// The limits as the server has them now.
  Future<void> loadConfig() async {
    final result = await _getConfig(fresh: true);
    result.fold(
      (_) {},
      (config) => emit(
        PostDraftState(
          text: state.text,
          config: config,
          rejected: state.rejected,
        ),
      ),
    );
  }

  /// She typed: a refusal no longer applies to what's there.
  void edit(String text) {
    if (text == state.text) return;
    emit(PostDraftState(text: text, config: state.config));
  }

  /// The filter refused the text (BA-A7).
  void refused() => emit(
    PostDraftState(text: state.text, config: state.config, rejected: true),
  );
}
