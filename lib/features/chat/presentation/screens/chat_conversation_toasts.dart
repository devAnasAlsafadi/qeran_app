import 'package:flutter/material.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/conversation_state.dart';

/// The toast, if any, that a conversation event raises.
void showConversationEventToast(BuildContext context, ConversationEvent event) {
  switch (event) {
    case ConversationEvent.none:
      break;
    case ConversationEvent.sendValidationEmpty:
      AppSnackBar.show(
        context,
        message: LocaleKeys.chat_send_validation_empty.t(context),
        type: SnackBarType.info,
      );
    case ConversationEvent.sendValidationTooLong:
      AppSnackBar.show(
        context,
        message: LocaleKeys.chat_send_validation_too_long.t(context),
        type: SnackBarType.info,
      );
    case ConversationEvent.sendRateLimited:
      AppSnackBar.show(
        context,
        message: LocaleKeys.chat_send_rate_limited.t(context),
        type: SnackBarType.info,
      );
    case ConversationEvent.sendConversationNotFound:
      AppSnackBar.show(
        context,
        message: LocaleKeys.chat_send_conversation_not_found.t(context),
        type: SnackBarType.error,
      );
    case ConversationEvent.sendUnauthorized:
      AppSnackBar.show(
        context,
        message: LocaleKeys.chat_send_unauthorized.t(context),
        type: SnackBarType.error,
      );
    case ConversationEvent.sendFailure:
      // No snackbar — the failed bubble itself carries the
      // tap-to-retry affordance. Showing a toast would double-
      // surface the failure.
      break;
    case ConversationEvent.shareProfileNotFound:
      AppSnackBar.show(
        context,
        message: LocaleKeys.chat_share_profile_not_found.t(context),
        type: SnackBarType.info,
      );
    case ConversationEvent.shareValidation:
      AppSnackBar.show(
        context,
        message: LocaleKeys.chat_share_validation.t(context),
        type: SnackBarType.info,
      );
    case ConversationEvent.shareRateLimited:
      AppSnackBar.show(
        context,
        message: LocaleKeys.chat_share_rate_limited.t(context),
        type: SnackBarType.info,
      );
    case ConversationEvent.shareConversationNotFound:
      AppSnackBar.show(
        context,
        message: LocaleKeys.chat_send_conversation_not_found.t(context),
        type: SnackBarType.error,
      );
    case ConversationEvent.shareUnauthorized:
      AppSnackBar.show(
        context,
        message: LocaleKeys.chat_send_unauthorized.t(context),
        type: SnackBarType.error,
      );
    case ConversationEvent.shareFailure:
      AppSnackBar.show(
        context,
        message: LocaleKeys.chat_share_failure.t(context),
        type: SnackBarType.error,
      );
    case ConversationEvent.shareSuccess:
      // No snackbar — the inserted message itself confirms.
      break;
  }
}
