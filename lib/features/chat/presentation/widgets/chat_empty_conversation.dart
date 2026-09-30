import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_monogram.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// A conversation with no messages yet: the peer's monogram and an invitation
/// to write first. Pull to refresh still works.
class ChatEmptyConversation extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final String peerName;
  const ChatEmptyConversation({
    super.key,
    required this.onRefresh,
    required this.peerName,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: QeranColors.wine,
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(QeranSpacing.s24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QeranMonogram(name: peerName, size: 72),
                      QeranSpacing.vs16,
                      Text(
                        LocaleKeys.chat_empty_title.t(context),
                        textAlign: TextAlign.center,
                        style: QeranTypography.subtitle.copyWith(
                          color: QeranColors.inkStrong,
                        ),
                      ),
                      QeranSpacing.vs8,
                      Text(
                        context.tr(
                          LocaleKeys.chat_empty_start_with,
                          namedArgs: {'peer': peerName},
                        ),
                        textAlign: TextAlign.center,
                        style: QeranTypography.body.copyWith(
                          color: QeranColors.inkMuted,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
