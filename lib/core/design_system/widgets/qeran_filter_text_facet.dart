import 'package:flutter/material.dart';

import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';
import 'qeran_text_field.dart';

/// A labelled free-text facet — a branded field feeding the same single-value
/// selection path the option facets use.
///
/// Stateful only to own its controller: the initial value is seeded once, so a
/// parent rebuild mid-typing never yanks the caret back.
class QeranFilterTextFacet extends StatefulWidget {
  const QeranFilterTextFacet({
    super.key,
    required this.label,
    required this.initial,
    required this.onChanged,
  });

  final String label;
  final String initial;
  final void Function(String value) onChanged;

  @override
  State<QeranFilterTextFacet> createState() => _QeranFilterTextFacetState();
}

class _QeranFilterTextFacetState extends State<QeranFilterTextFacet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: QeranTypography.subtitle),
        QeranSpacing.vs8,
        QeranTextField(
          controller: _controller,
          hint: widget.label,
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}
