part of 'legal_document_cubit.dart';

/// State for the legal screen. Every state carries the [type] currently being
/// shown so the segmented toggle stays in sync with the content.
sealed class LegalDocumentState extends Equatable {
  const LegalDocumentState(this.type);

  final LegalDocumentType type;

  @override
  List<Object?> get props => [type];
}

final class LegalDocumentLoading extends LegalDocumentState {
  const LegalDocumentLoading(super.type);
}

final class LegalDocumentLoaded extends LegalDocumentState {
  const LegalDocumentLoaded(super.type, this.document);

  final LegalDocument document;

  @override
  List<Object?> get props => [type, document];
}

final class LegalDocumentError extends LegalDocumentState {
  const LegalDocumentError(super.type, this.message);

  /// A locale key or a backend message — render via `.t(context)` (a no-op for
  /// a non-key string).
  final String message;

  @override
  List<Object?> get props => [type, message];
}
