import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The Likes tabs' loading state — the brand loader with a soft caption below,
/// so a slow fetch reads as "loading your interests" rather than a bare spinner.
class LikesLoadingView extends StatelessWidget {
  const LikesLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const QeranLoader(),
          QeranSpacing.vs16,
          Text(
            LocaleKeys.likes_loading_caption.t(context),
            style: QeranTypography.bodySm.copyWith(color: QeranColors.inkMuted),
          ),
        ],
      ),
    );
  }
}
