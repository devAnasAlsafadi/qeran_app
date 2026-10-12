import 'package:flutter/material.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/chat/presentation/screens/my_matchmaker_chat_page.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/matchmaker_inquiry_state.dart';

/// The inquiry's own outcomes, on their own listener.
///
/// Four arms rather than four of forty. Its enum holds only what this cubit
/// can emit, so the switch stays exhaustive AND every arm is reachable — a
/// new inquiry outcome is a compile error here, which is the property a
/// shared forty-member enum would have buried. Its own file, as
/// `onMatchActionEvent` is, so the screen stays a screen.
void onInquiryEvent(BuildContext context, MatchmakerInquiryState state) {
  switch (state.event) {
    case InquiryEvent.none:
      break;
    // Open the chat, freshly loaded, so the newly posted profile card and
    // text are visible immediately. The formal step does not join this: it
    // posts nothing to the matchmaker, so there would be nothing to show.
    case InquiryEvent.success:
    case InquiryEvent.alreadySent:
      openMatchmakerChat(context);
    // No one to ask yet, never assigned or hers deleted: the line the chat
    // shows a member waiting for one, calm rather than an error.
    case InquiryEvent.noMatchmaker:
      AppSnackBar.show(
        context,
        message: LocaleKeys.chat_entry_no_matchmaker_title.t(context),
        type: SnackBarType.info,
      );
    case InquiryEvent.failure:
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_action_request_failed.t(context),
        type: SnackBarType.error,
      );
  }
}
