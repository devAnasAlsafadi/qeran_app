import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/widgets/qeran_empty_state.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class ProfileDetailsNotAvailableView extends StatelessWidget {
  const ProfileDetailsNotAvailableView({super.key});

  @override
  Widget build(BuildContext context) {
    return QeranEmptyState(
      title: LocaleKeys.profile_not_available.t(context),
      icon: Icons.person_off_outlined,
    );
  }
}
