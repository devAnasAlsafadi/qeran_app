import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/widgets/qeran_error_state.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class ProfileDetailsErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ProfileDetailsErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return QeranErrorState(
      title: message.t(context),
      retryLabel: LocaleKeys.profile_retry.t(context),
      onRetry: onRetry,
    );
  }
}
