import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_card.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The two names as they stand today. Both are read-only here: the display
/// name is edited by the form below, and the real name is never editable from
/// the app — the backend collects it at the formal-agreement stage.
class DisplayNameReadOnlyCard extends StatelessWidget {
  const DisplayNameReadOnlyCard({
    super.key,
    required this.displayName,
    required this.realName,
  });

  final String displayName;

  /// Null when the member has no real name on file yet.
  final String? realName;

  @override
  Widget build(BuildContext context) {
    return QeranCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _ReadOnlyField(
            label: LocaleKeys.profile_name_display_label.t(context),
            value: displayName,
          ),
          QeranSpacing.vs16,
          _ReadOnlyField(
            label: LocaleKeys.profile_name_real_label.t(context),
            value: realName ?? LocaleKeys.profile_name_real_empty.t(context),
            muted: realName == null,
          ),
          QeranSpacing.vs8,
          Text(
            LocaleKeys.profile_name_real_note.t(context),
            style: QeranTypography.caption.copyWith(
              color: QeranColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Label above value. The value carries the emphasis — the reverse of
/// [SettingsRow], which mutes its subtitle.
class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
    this.muted = false,
  });

  final String label;
  final String value;

  /// Renders the value as a placeholder rather than real content.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: QeranTypography.bodySm.copyWith(color: QeranColors.inkBody),
        ),
        QeranSpacing.vs4,
        Text(
          value,
          style: QeranTypography.subtitle.copyWith(
            color: muted ? QeranColors.inkFaint : QeranColors.inkStrong,
          ),
        ),
      ],
    );
  }
}
