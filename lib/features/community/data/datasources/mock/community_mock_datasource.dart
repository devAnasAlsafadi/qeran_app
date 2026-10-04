import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/services/connectivity_service.dart';
import 'package:qeran/features/report/domain/entities/report_reason.dart';
import 'package:qeran/features/report/domain/entities/report_target.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../error_codes.dart';
import '../../models/community_comment_model.dart';
import '../../models/community_config_model.dart';
import '../../models/community_guidelines_model.dart';
import '../../models/community_like_state_model.dart';
import '../../models/community_page_model.dart';
import '../../models/community_post_model.dart';
import '../community_remote_datasource.dart';
import 'community_mock_documents.dart';
import 'community_mock_rules.dart';
import 'community_mock_store.dart';

/// Community in memory: the test fake, and the dev-flag states (Q2). It
/// throws exactly what `HttpConsumer` would, and its JSON goes through the
/// same models as the live API's. Reports stay in memory too: a made-up id
/// never reaches the real endpoint (Q3).
///
/// Gates run in the server's order (contract §4): an injected fault
/// ([failNextCallWith] — `PROFILE_NOT_APPROVED`, `DISPLAY_NAME_REQUIRED`,
/// which only the real profile knows), guidelines, validation, the rate
/// limit, then the filter.
class CommunityMockDataSource implements CommunityRemoteDataSource {
  final CommunityMockStore store;
  final Duration latency;
  final ConnectivityService? connectivity;
  final bool failEverything;
  final CommunityMockCommentGate _gate;
  final List<String> _faults = [];

  CommunityMockDataSource({
    required this.store,
    this.latency = Duration.zero,
    this.connectivity,
    this.failEverything = false,
    bool guidelinesAccepted = false,
  }) : _gate = CommunityMockCommentGate(
          store.now,
          viewerIsMatchmaker: store.viewer.isMatchmaker,
          guidelinesAccepted: guidelinesAccepted,
        );

  bool get guidelinesAccepted => _gate.guidelinesAccepted;

  /// The next call — whatever it is — fails with [errorCode].
  void failNextCallWith(String errorCode) => _faults.add(errorCode);

  @override
  Future<CommunityPageModel<CommunityPostModel>> getFeed({
    required int page,
    required int pageSize,
  }) =>
      _run(() => CommunityPageModel.fromJson(
            store.feedPage(page, pageSize),
            CommunityPostModel.fromJson,
          ));

  @override
  Future<CommunityPostModel> getPost(int postId) =>
      _run(() => CommunityPostModel.fromJson(store.post(postId)));

  @override
  Future<CommunityLikeStateModel> setPostLike(int postId, {required bool liked}) =>
      _run(() => CommunityLikeStateModel.fromJson(
            store.setPostLike(postId, liked: liked),
          ));

  @override
  Future<CommunityLikeStateModel> setCommentLike(
    int commentId, {
    required bool liked,
  }) =>
      _run(() => CommunityLikeStateModel.fromJson(
            store.setCommentLike(commentId, liked: liked),
          ));

  @override
  Future<CommunityPageModel<CommunityCommentModel>> getComments(
    int postId, {
    required int page,
    required int pageSize,
  }) =>
      _run(() => CommunityPageModel.fromJson(
            store.commentsPage(postId, page, pageSize),
            CommunityCommentModel.fromJson,
          ));

  @override
  Future<CommunityPageModel<CommunityCommentModel>> getReplies(
    int commentId, {
    required int page,
    required int pageSize,
  }) =>
      _run(() => CommunityPageModel.fromJson(
            store.repliesPage(commentId, page, pageSize),
            CommunityCommentModel.fromJson,
          ));

  @override
  Future<CommunityCommentModel> getComment(int commentId) =>
      _run(() => CommunityCommentModel.fromJson(store.comment(commentId)));

  @override
  Future<CommunityCommentModel> createComment(int postId, String text) =>
      _run(() {
        store.requirePost(postId);
        _gate.check(text, maxLength: _maxLength);
        return CommunityCommentModel.fromJson(
          store.addComment(postId: postId, text: text.trim()),
        );
      });

  @override
  Future<CommunityCommentModel> createReply(int commentId, String text) =>
      _run(() {
        final parent = store.requireComment(commentId);
        if (parent.parentId != null) {
          throwCommunityMockError(CommunityErrorCodes.validationError);
        }
        _gate.check(text, maxLength: _maxLength);
        return CommunityCommentModel.fromJson(store.addComment(
          postId: parent.postId,
          parentId: commentId,
          text: text.trim(),
        ));
      });

  @override
  Future<void> deleteComment(int commentId) =>
      _run(() => store.deleteComment(commentId));

  @override
  Future<CommunityConfigModel> getConfig() =>
      _run(() => CommunityConfigModel.fromJson(communityMockConfig()));

  @override
  Future<CommunityGuidelinesModel> getGuidelines() =>
      _run(() => CommunityGuidelinesModel.fromJson(communityMockGuidelines()));

  @override
  Future<void> acceptGuidelines(int version) => _run(() {
        if (version != communityMockGuidelinesVersion) {
          throwCommunityMockError(CommunityErrorCodes.validationError);
        }
        _gate.guidelinesAccepted = true;
      });

  @override
  Future<void> reportContent(
    ContentReportTarget target, {
    required ReportReason reason,
    String? note,
  }) => _run(() => store.report(target));

  @override
  Future<void> blockMember(String userId) => _run(() => store.block(userId));

  static int get _maxLength =>
      communityMockConfig()['commentMaxLength'] as int;

  Future<T> _run<T>(T Function() body) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (connectivity case final ConnectivityService c
        when !await c.isOnline) {
      throw const OfflineException();
    }
    if (failEverything) {
      throw ServerException(message: LocaleKeys.errors_server);
    }
    if (_faults.isNotEmpty) throwCommunityMockError(_faults.removeAt(0));
    return body();
  }
}
