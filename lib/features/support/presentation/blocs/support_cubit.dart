import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../data/error_codes.dart';
import '../../domain/entities/support_category.dart';
import '../../domain/usecases/create_support_ticket_usecase.dart';
import '../../domain/usecases/get_support_categories_usecase.dart';

part 'support_state.dart';

/// Drives the Help & Support form: loads the problem-type list, then submits a
/// real ticket. A single in-flight slot guards double-submit; every terminal
/// submit outcome bumps `eventVersion` so the screen toasts (and pops on
/// success) exactly once. The 5-open-tickets cap is flagged separately.
class SupportCubit extends Cubit<SupportState> {
  final GetSupportCategoriesUseCase _getCategories;
  final CreateSupportTicketUseCase _createTicket;

  SupportCubit({
    required GetSupportCategoriesUseCase getCategories,
    required CreateSupportTicketUseCase createTicket,
  })  : _getCategories = getCategories,
        _createTicket = createTicket,
        super(const SupportState());

  Future<void> loadCategories() async {
    emit(state.copyWith(categoriesStatus: SupportCategoriesStatus.loading));
    final result = await _getCategories();
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        categoriesStatus: SupportCategoriesStatus.failure,
        categoriesErrorKey: failure.message,
      )),
      (categories) => emit(state.copyWith(
        categoriesStatus: SupportCategoriesStatus.loaded,
        categories: categories,
      )),
    );
  }

  Future<void> submit({
    required int categoryId,
    required String subject,
    required String details,
  }) async {
    if (state.isSubmitting) return; // guard double-submit
    emit(state.copyWith(submitStatus: SupportSubmitStatus.submitting));
    final result = await _createTicket(
      categoryId: categoryId,
      subject: subject,
      details: details,
    );
    if (isClosed) return;
    result.fold(
      (failure) {
        final limitReached = failure is CodedServerFailure &&
            failure.errorCode == SupportErrorCodes.limitReached;
        AppLogger.warning(
          'SUPPORT — submit failed limit=$limitReached',
          tag: 'SUPPORT',
        );
        emit(state.copyWith(
          submitStatus: SupportSubmitStatus.failure,
          submitMessage: failure.message,
          submitLimitReached: limitReached,
          eventVersion: state.eventVersion + 1,
        ));
      },
      (_) => emit(state.copyWith(
        submitStatus: SupportSubmitStatus.success,
        submitMessage: LocaleKeys.settings_support_success,
        submitLimitReached: false,
        eventVersion: state.eventVersion + 1,
      )),
    );
  }
}
