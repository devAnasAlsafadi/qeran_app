import 'package:qeran/core/di/injection_container.dart';

import 'blocs/user_session/user_session_cubit.dart';

/// The signed-in account is a matchmaker. False with no session — or with no
/// session cubit registered (a widget test).
bool get signedInAsMatchmaker =>
    sl.isRegistered<UserSessionCubit>() &&
    (sl<UserSessionCubit>().currentUser?.isMatchmaker ?? false);

/// Copy that addresses its reader, shared by both apps.
extension ReaderCopy on String {
  /// This locale key, or [her] when the signed-in reader is a matchmaker: in
  /// her app a string that speaks to the reader takes the feminine — every
  /// matchmaker is a woman («خطّابة», Q9 of Phase 3) — while the member's app
  /// keeps the generic form. English reads the same either way.
  String forReader({required String her}) => signedInAsMatchmaker ? her : this;
}
