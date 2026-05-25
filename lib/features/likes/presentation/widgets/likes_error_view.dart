import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/widgets/qeran_error_state.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Compact error state with a retry button. Used whenever the
/// incoming / outgoing fetch returns `Left(Failure)`.
///
/// Raw backend strings are intentionally NOT rendered — the message
/// falls back to the generic `errors.generic` description. The raw
/// message is logged at the cubit / repository layer.
class LikesErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const LikesErrorView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return QeranErrorState(
      title: LocaleKeys.likes_error_title.t(context),
      message: LocaleKeys.errors_generic.t(context),
      retryLabel: LocaleKeys.likes_error_retry.t(context),
      onRetry: onRetry,
    );
  }
}
