import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_monogram.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/features/likes/presentation/widgets/like_blurred_image.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/matchmaker_info.dart';

class ChatHeader extends StatelessWidget {
  final MatchmakerInfo info;
  final VoidCallback? onBack;
  final VoidCallback? onTap;

  /// Whether our realtime socket is connected — drives the neutral "active
  /// now" status. Bound to OUR connection (not fabricated peer presence).
  final bool isActive;

  const ChatHeader({
    super.key,
    required this.info,
    this.onBack,
    this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: QeranColors.paper,
        border: Border(bottom: BorderSide(color: QeranColors.wine08)),
        boxShadow: QeranShadows.e1,
      ),
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s16,
        QeranSpacing.s12,
        QeranSpacing.s16,
        QeranSpacing.s12,
      ),
      child: SafeArea(
        bottom: false,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              if (onBack != null) ...[
                _HeaderBackButton(onBack: onBack!),
                QeranSpacing.hs4,
              ],
              _HeaderAvatar(url: info.profileImageUrl, name: info.name),
              QeranSpacing.hs12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      info.name,
                      style: QeranTypography.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Neutral, role-agnostic status — shown only while our
                    // realtime link is up (the reconnecting strip covers the
                    // rest), so it never claims presence we can't back.
                    if (isActive) ...[
                      QeranSpacing.vs4,
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: QeranColors.goldDeep,
                              shape: BoxShape.circle,
                            ),
                          ),
                          QeranSpacing.hs4,
                          Text(
                            LocaleKeys.chat_header_status_active.t(context),
                            style: QeranTypography.caption.copyWith(
                              color: QeranColors.goldDeep,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Leading back affordance for the header — shown only when
/// `ChatConversationScreen.onBack` is set (pushed-route usage). Transparent
/// host since the header is already on a paper surface.
class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onBack,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Icon(
              Icons.chevron_left_rounded,
              color: QeranColors.wine,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

/// Header peer avatar — the real photo (unblurred; the parties are already
/// connected) inside a gold ring, falling back to the wine+gold monogram
/// when there's no photo.
class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return QeranMonogram(name: name, size: 44, borderWidth: 1.2);
    }
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: QeranColors.gold, width: 1.2),
      ),
      child: LikeBlurredImage(
        url: url,
        blur: false,
        size: 40,
        fallbackIcon: Icons.person_rounded,
      ),
    );
  }
}
