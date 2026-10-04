import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';

/// The viewer's top row (G1, G4): close at the start, and — for a set of
/// photos — "2 / 4" in the middle, left to right in every language.
class ViewerTopBar extends StatelessWidget {
  const ViewerTopBar({super.key, required this.onClose, this.counter});

  final VoidCallback onClose;
  final String? counter;

  @override
  Widget build(BuildContext context) {
    final counter = this.counter;
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (counter != null) _counter(counter),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: _Close(onTap: onClose),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _counter(String text) => Text(
    text,
    textDirection: TextDirection.ltr,
    style: QeranTypography.numeric.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: QeranColors.paper,
    ),
  );
}

/// Close: a 48 pt tap area, the icon in paper.
class _Close extends StatelessWidget {
  const _Close({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: LocaleKeys.community_viewer_close.t(context),
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: const SizedBox.square(
          dimension: 48,
          child: Icon(Icons.close_rounded, size: 26, color: QeranColors.paper),
        ),
      ),
    );
  }
}
