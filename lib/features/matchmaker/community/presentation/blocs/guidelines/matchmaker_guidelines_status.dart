import 'package:qeran/features/matchmaker/account/domain/usecases/get_me_usecase.dart';

/// Whether she still owes the posting guidelines before her first post (D7,
/// G1). App-scoped and forgotten with the account (AccountScope): her
/// `communityGuidelinesAccepted` is read from `GET matchmaker/me` until it
/// says she has, and is set the moment she agrees.
///
/// Only a plain "not accepted" opens the guidelines. A read that fails, or a
/// `me` that doesn't say, lets her go on: the server is the real gate, and
/// its `COMMUNITY_GUIDELINES_NOT_ACCEPTED` on publish opens them then.
class MatchmakerGuidelinesStatus {
  MatchmakerGuidelinesStatus({required GetMeUseCase getMe}) : _getMe = getMe;

  final GetMeUseCase _getMe;
  bool _accepted = false;

  /// Bumped when the account changes: a read in flight is the previous
  /// account's, so its answer isn't kept.
  int _generation = 0;

  Future<bool> owed() async {
    if (_accepted) return false;
    final generation = _generation;
    final result = await _getMe();
    if (generation != _generation) return false;
    return result.fold((_) => false, (me) {
      _accepted = me.communityGuidelinesAccepted == true;
      return me.communityGuidelinesAccepted == false;
    });
  }

  /// She agreed (or the server's answer says she has).
  void markAccepted() => _accepted = true;

  /// The account changed: the next one is asked again.
  void forget() {
    _generation++;
    _accepted = false;
  }
}
