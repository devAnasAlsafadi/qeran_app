import 'package:flutter_bloc/flutter_bloc.dart';

/// Async status for the support-request submission.
enum SupportStatus { idle, submitting, success, failure }

class SupportState {
  final SupportStatus status;
  const SupportState(this.status);
}

/// Placeholder cubit for the Help & Support form.
///
/// Placeholder until the support endpoint exists. Expected contract:
/// `POST {EndPoints.baseUrl}/api/support` with body
/// `{ "type": category, "subject": string, "details": string }` and the
/// standard `{ status, data, message }` envelope. Until then [submit]
/// simulates a successful submission so the UI is fully testable and the
/// endpoint can be slotted in with no UI changes.
class SupportCubit extends Cubit<SupportState> {
  SupportCubit() : super(const SupportState(SupportStatus.idle));

  Future<void> submit({
    required String type,
    required String subject,
    required String details,
  }) async {
    if (state.status == SupportStatus.submitting) return;
    emit(const SupportState(SupportStatus.submitting));
    // TODO(backend): replace with the real ApiConsumer POST call.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    emit(const SupportState(SupportStatus.success));
  }
}
