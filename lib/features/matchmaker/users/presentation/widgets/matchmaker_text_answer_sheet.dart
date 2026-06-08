import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/profile/domain/entities/placement_item.dart';
import 'package:qeran/features/profile/domain/entities/placement_value.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_sheet_handle.dart';
import '../../../../../core/design_system/widgets/qeran_text_field.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../blocs/matchmaker_answer_save_cubit.dart';
import '../blocs/matchmaker_answer_save_state.dart';

/// Inline editor for one TEXT placement answer. Shares the screen's
/// [MatchmakerAnswerSaveCubit] (so the per-item pencil loader + the screen's
/// success snackbar/refresh all observe the same save). Prefilled with the
/// current answer; Save → `cubit.save`; on a successful save it pops itself
/// (the host shows the toast + refreshes the profile).
Future<void> showMatchmakerTextAnswerSheet(
  BuildContext context, {
  required MatchmakerAnswerSaveCubit cubit,
  required PlacementItem item,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: QeranColors.paper,
    shape: const RoundedRectangleBorder(borderRadius: QeranRadii.domeTop),
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _TextAnswerSheet(item: item),
    ),
  );
}

class _TextAnswerSheet extends StatefulWidget {
  const _TextAnswerSheet({required this.item});

  final PlacementItem item;

  @override
  State<_TextAnswerSheet> createState() => _TextAnswerSheetState();
}

class _TextAnswerSheetState extends State<_TextAnswerSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: _current);

  String get _current => switch (widget.item.display) {
        PlacementSingle(value: final v) => v,
        PlacementMulti(values: final vs) => vs.join('\n'),
      };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSave {
    final text = _controller.text.trim();
    return text.isNotEmpty && text != _current.trim();
  }

  void _save(MatchmakerAnswerSaveCubit cubit) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    cubit.save(questionId: widget.item.questionId, textAnswer: text);
  }

  void _onOutcome(BuildContext context, MatchmakerAnswerSaveState state) {
    // The host owns the toast + profile refresh; the sheet just closes once
    // its own save succeeds.
    if (state.outcome == AnswerSaveOutcome.success &&
        state.lastQuestionId == widget.item.questionId) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MatchmakerAnswerSaveCubit>();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s12,
        QeranSpacing.s20,
        QeranSpacing.s20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: BlocConsumer<MatchmakerAnswerSaveCubit, MatchmakerAnswerSaveState>(
        listenWhen: (p, c) => p.eventVersion != c.eventVersion,
        listener: _onOutcome,
        builder: (context, state) {
          final saving = state.isSaving(widget.item.questionId);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: QeranSheetHandle()),
              QeranSpacing.vs16,
              Text(widget.item.question, style: QeranTypography.title),
              QeranSpacing.vs16,
              QeranTextField(
                controller: _controller,
                hint: LocaleKeys.matchmaker_answers_hint.t(context),
                maxLines: 4,
                onChanged: (_) => setState(() {}),
              ),
              QeranSpacing.vs20,
              QeranButton(
                label: LocaleKeys.matchmaker_answers_save.t(context),
                variant: QeranButtonVariant.primaryWine,
                loading: saving,
                onPressed:
                    (saving || !_canSave) ? null : () => _save(cubit),
              ),
            ],
          );
        },
      ),
    );
  }
}
