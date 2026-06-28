import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/di/injection_container.dart';

import '../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../settings/presentation/widgets/settings_screen_header.dart';
import '../../domain/entities/legal_document.dart';
import '../../domain/entities/legal_document_type.dart';
import '../blocs/legal_document_cubit.dart';
import '../widgets/legal_segmented_toggle.dart';

/// Dynamic Terms & Privacy screen — a segmented toggle over the two public
/// legal endpoints, content fetched live (no static fallback). Qeran design
/// system throughout; bilingual by app locale; RTL via ambient Directionality.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LegalDocumentCubit>()
        ..load(LegalDocumentType.termsAndConditions),
      child: const _LegalView(),
    );
  }
}

class _LegalView extends StatelessWidget {
  const _LegalView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsScreenHeader(title: LocaleKeys.legal_title.t(context)),
            Expanded(
              child: BlocBuilder<LegalDocumentCubit, LegalDocumentState>(
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LegalSegmentedToggle(
                        active: state.type,
                        onChanged: context.read<LegalDocumentCubit>().load,
                      ),
                      Expanded(child: _content(context, state)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, LegalDocumentState state) {
    switch (state) {
      case LegalDocumentLoading():
        return const Center(child: QeranLoader());
      case LegalDocumentError(:final message):
        return QeranErrorState(
          title: LocaleKeys.legal_error_title.t(context),
          message: message.t(context),
          retryLabel: LocaleKeys.legal_error_retry.t(context),
          onRetry: () => context.read<LegalDocumentCubit>().retry(),
        );
      case LegalDocumentLoaded(:final document):
        if (document.isEmpty) {
          return Center(
            child: Text(
              LocaleKeys.legal_empty.t(context),
              style: QeranTypography.body.copyWith(color: QeranColors.inkMuted),
            ),
          );
        }
        return _DocumentBody(document: document);
    }
  }
}

class _DocumentBody extends StatelessWidget {
  const _DocumentBody({required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final lastUpdatedAt = document.lastUpdatedAt;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s8,
        QeranSpacing.s20,
        QeranSpacing.s32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lastUpdatedAt != null) ...[
            Text(
              context.tr(
                LocaleKeys.legal_last_updated,
                namedArgs: {
                  'date': DateFormat.yMMMMd(context.locale.toString())
                      .format(lastUpdatedAt.toLocal()),
                },
              ),
              style: QeranTypography.caption,
            ),
            QeranSpacing.vs20,
          ],
          for (final section in document.sections)
            _LegalSectionView(section: section, isAr: isAr),
        ],
      ),
    );
  }
}

class _LegalSectionView extends StatelessWidget {
  const _LegalSectionView({required this.section, required this.isAr});

  final LegalSection section;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: QeranSpacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? section.titleAr : section.titleEn,
            style: QeranTypography.title,
          ),
          QeranSpacing.vs8,
          Text(
            isAr ? section.bodyAr : section.bodyEn,
            textAlign: TextAlign.start,
            style: QeranTypography.body.copyWith(height: 1.7),
          ),
        ],
      ),
    );
  }
}
