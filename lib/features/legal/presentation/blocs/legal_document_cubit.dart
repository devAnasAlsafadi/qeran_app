import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/legal_document.dart';
import '../../domain/entities/legal_document_type.dart';
import '../../domain/usecases/get_legal_document_usecase.dart';

part 'legal_document_state.dart';

/// Drives the legal screen: loads the selected document, caching each fetched
/// document so toggling back to an already-loaded tab is instant (no refetch).
class LegalDocumentCubit extends Cubit<LegalDocumentState> {
  final GetLegalDocumentUseCase _getDocument;
  final Map<LegalDocumentType, LegalDocument> _cache = {};

  LegalDocumentCubit({required GetLegalDocumentUseCase getDocument})
      : _getDocument = getDocument,
        super(const LegalDocumentLoading(LegalDocumentType.termsAndConditions));

  /// Loads [type] — instantly from cache when available, else fetches.
  Future<void> load(LegalDocumentType type) async {
    final cached = _cache[type];
    if (cached != null) {
      emit(LegalDocumentLoaded(type, cached));
      return;
    }
    emit(LegalDocumentLoading(type));
    final result = await _getDocument(type);
    if (isClosed) return;
    result.fold(
      (failure) => emit(LegalDocumentError(type, failure.message)),
      (document) {
        _cache[type] = document;
        emit(LegalDocumentLoaded(type, document));
      },
    );
  }

  /// Retries the document currently in view (after an error).
  Future<void> retry() => load(state.type);
}
