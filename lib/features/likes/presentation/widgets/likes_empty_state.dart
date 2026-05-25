import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/widgets/qeran_empty_state.dart';
import 'package:qeran/core/extensions/localization_extension.dart';

/// Premium empty-state — soft icon, two-line copy, no action button so
/// the layout reads as "nothing here yet" rather than a dead-end error.
class LikesEmptyState extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final String subtitleKey;

  const LikesEmptyState({
    super.key,
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
  });

  @override
  Widget build(BuildContext context) {
    return QeranEmptyState(
      title: titleKey.t(context),
      message: subtitleKey.t(context),
      icon: icon,
    );
  }
}
