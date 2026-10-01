import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_count_badge.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The Suggestions title, with the «تعديل الفلترة» pill at its end.
///
/// It keeps one spot in every state: on the photo when a card is loaded
/// ([onPhoto] — paper type over the photo's top scrim), on the canvas
/// otherwise. The pill shows where filters can help, so not on an error or the
/// daily limit ([showFilters]); with no [onEditFilters] it is drawn at half
/// strength and does nothing, as while the first page loads. While filters
/// narrow the deck, the pill carries their number ([activeFilterCount]).
class DiscoveryTitleRow extends StatelessWidget {
  const DiscoveryTitleRow({
    super.key,
    required this.onPhoto,
    required this.activeFilterCount,
    this.showFilters = true,
    this.onEditFilters,
  });

  final bool onPhoto;
  final bool showFilters;
  final VoidCallback? onEditFilters;

  /// How many filter questions narrow the deck; 0 draws no badge.
  final int activeFilterCount;

  static const double _height = 48;
  static const double _pillMaxShare = 0.6;

  /// From the top of the Suggestions area to the row's bottom edge: where a
  /// state that isn't a loaded card starts its content.
  static const double extent = QeranSpacing.s8 + _height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: QeranSpacing.s8,
        start: QeranSpacing.s20,
        end: QeranSpacing.s12,
      ),
      child: SizedBox(
        height: _height,
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: QeranColors.gold,
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
                child: SizedBox(width: 3, height: 20),
              ),
              QeranSpacing.hs12,
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    LocaleKeys.discovery_title.t(context),
                    style: QeranTypography.title.copyWith(
                      color: onPhoto
                          ? QeranColors.paper
                          : QeranColors.inkStrong,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (showFilters)
                // A long label or a large text size shortens the pill's label,
                // not the title's room.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * _pillMaxShare,
                  ),
                  child: _FiltersPill(
                    onPhoto: onPhoto,
                    onTap: onEditFilters,
                    activeCount: activeFilterCount,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «تعديل الفلترة»: dark wine glass on the photo, a raised paper pill on the
/// canvas. The count rides its top-end corner, as the bell carries its own;
/// the row's padding leaves room for it, so nothing that holds the row clips
/// it.
class _FiltersPill extends StatelessWidget {
  const _FiltersPill({
    required this.onPhoto,
    required this.onTap,
    required this.activeCount,
  });

  final bool onPhoto;
  final VoidCallback? onTap;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      onTap: onTap,
      label: activeCount > 0
          ? LocaleKeys.discovery_filter_button_active_a11y.t(
              context,
              namedArgs: {'count': '$activeCount'},
            )
          : LocaleKeys.discovery_filter_button.t(context),
      excludeSemantics: true,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _pill(context),
            if (activeCount > 0)
              PositionedDirectional(
                top: -QeranSpacing.s4,
                end: -QeranSpacing.s4,
                child: QeranCountBadge(count: activeCount),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pill(BuildContext context) {
    final ink = onPhoto ? QeranColors.paper : QeranColors.wine;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: onPhoto ? QeranColors.overlayTintDark : QeranColors.paper,
        shape: const StadiumBorder(),
        shadows: onPhoto ? null : QeranShadows.e1,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: QeranSpacing.s12,
                end: QeranSpacing.s16,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, size: 18, color: ink),
                  const SizedBox(width: QeranSpacing.s6),
                  Flexible(
                    child: Text(
                      LocaleKeys.discovery_filter_button.t(context),
                      style: QeranTypography.label.copyWith(color: ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
