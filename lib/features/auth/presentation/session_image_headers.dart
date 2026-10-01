import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_image_headers.dart';
import 'blocs/user_session/user_session_cubit.dart';
import 'blocs/user_session/user_session_state.dart';

/// The headers for loading the image at [url] as the signed-in user: the
/// session's Bearer token, but only when [url] is on our own API's origin
/// ([imageHeadersFor]) — the token never reaches another host.
///
/// Signed out, or with no session in scope (widget tests), there are none:
/// the request goes out anonymously and the server's 401 shows the image's
/// fallback — never a crash.
Map<String, String>? sessionImageHeaders(BuildContext context, String url) {
  String? token;
  try {
    final state = context.read<UserSessionCubit>().state;
    if (state is UserSessionAuthenticated) token = state.user.token;
  } catch (_) {
    // No session in scope: anonymous.
  }
  return imageHeadersFor(url, token: token);
}
