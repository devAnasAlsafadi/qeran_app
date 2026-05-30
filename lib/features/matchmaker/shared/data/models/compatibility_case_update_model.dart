import '../../domain/entities/compatibility_case_update.dart';
import '../json_parsers.dart';

/// Maps the `CompatibilityCaseUpdated` wire payload (camelCase) to its
/// entity. Parsing is tolerant (shared `json_parsers`); the event parser
/// that wraps this guarantees never-throw / null-on-malformed at the
/// dispatch site.
class CompatibilityCaseUpdateModel {
  const CompatibilityCaseUpdateModel._();

  static CompatibilityCaseUpdate fromJson(Map<String, dynamic> json) {
    return CompatibilityCaseUpdate(
      caseId: parseInt(json['caseId']),
      formalRequestId: parseInt(json['formalRequestId']),
      newStatus: parseString(json['newStatus']),
      newStatusCode: parseInt(json['newStatusCode']),
      updatedAt: parseNullableDateTime(json['updatedAt']),
    );
  }
}
