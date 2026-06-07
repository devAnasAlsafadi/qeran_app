import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_app_bar.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/enum/snakebar_tybe.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../../../../generated/locale_keys.g.dart';

/// One social link: icon + localized platform name + url.
class _Link {
  const _Link(this.icon, this.labelKey, this.url);
  final IconData icon;
  final String labelKey;
  final String url;
}

// ⚠️ TODO(product): replace with the real Qeran social URLs/handles. These are
// brand-domain placeholders so the screen is functional (copy-to-clipboard) —
// no url_launcher dependency is added (tap copies the link).
const List<_Link> _links = [
  _Link(Icons.language_rounded, LocaleKeys.matchmaker_account_contact_website,
      'https://qeran.com'),
  _Link(Icons.camera_alt_outlined,
      LocaleKeys.matchmaker_account_contact_instagram,
      'https://instagram.com/qeran'),
  _Link(Icons.chat_rounded, LocaleKeys.matchmaker_account_contact_whatsapp,
      'https://wa.me/qeran'),
  _Link(Icons.facebook_outlined,
      LocaleKeys.matchmaker_account_contact_facebook,
      'https://facebook.com/qeran'),
  _Link(Icons.alternate_email_rounded, LocaleKeys.matchmaker_account_contact_x,
      'https://x.com/qeran'),
];

/// Contact-us screen — static social links (no backend, no url_launcher). Each
/// row copies its link to the clipboard. Pushed from the account screen.
class MatchmakerContactScreen extends StatelessWidget {
  const MatchmakerContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: QeranAppBar(
        title: LocaleKeys.matchmaker_account_contact.t(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(QeranSpacing.s16),
        children: [
          QeranCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < _links.length; i++) ...[
                  if (i > 0) const _Divider(),
                  _ContactRow(link: _links[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.link});

  final _Link link;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: link.url));
    if (!context.mounted) return;
    AppSnackBar.show(
      context,
      message: LocaleKeys.matchmaker_account_contact_copied.t(context),
      type: SnackBarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => _copy(context),
        splashColor: QeranColors.creamSurface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: QeranColors.creamSurface,
                ),
                alignment: Alignment.center,
                child: Icon(link.icon, size: 20, color: QeranColors.wine),
              ),
              QeranSpacing.hs12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      link.labelKey.t(context),
                      style: QeranTypography.body
                          .copyWith(color: QeranColors.wine),
                    ),
                    QeranSpacing.vs4,
                    Text(
                      link.url,
                      style: QeranTypography.caption
                          .copyWith(color: QeranColors.inkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.copy_rounded,
                size: 18,
                color: QeranColors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsetsDirectional.only(start: 60, end: 16),
      child: SizedBox(
        height: 1,
        child: ColoredBox(color: QeranColors.divider),
      ),
    );
  }
}
