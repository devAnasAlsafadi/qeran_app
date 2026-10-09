part of 'onboarding_community_card.dart';

/// A gold glyph centred in a [box]-sized frame: the header's ring, a topic's
/// square.
class _Glyph extends StatelessWidget {
  final IconData icon;
  final double box;
  final double iconSize;
  final BoxDecoration decoration;

  const _Glyph({
    required this.icon,
    required this.box,
    required this.iconSize,
    required this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: box,
      height: box,
      alignment: Alignment.center,
      decoration: decoration,
      child: Icon(icon, size: iconSize, color: QeranColors.gold),
    );
  }
}

/// A paper title over a gold meta line, each one line long — the header's
/// larger, a topic's smaller.
class _TwoLines extends StatelessWidget {
  final String title;
  final String meta;
  final bool header;

  const _TwoLines({
    required this.title,
    required this.meta,
    this.header = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = header
        ? QeranTypography.subtitle
        : QeranTypography.label;
    final metaStyle = header ? QeranTypography.bodySm : QeranTypography.caption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: titleStyle.copyWith(color: QeranColors.paper),
        ),
        Text(
          meta,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: metaStyle.copyWith(color: QeranColors.gold),
        ),
      ],
    );
  }
}
