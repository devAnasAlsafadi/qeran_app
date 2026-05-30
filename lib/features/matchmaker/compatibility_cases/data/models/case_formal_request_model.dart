import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/case_formal_request.dart';
import '../../domain/entities/formal_request_status.dart';

/// Wire model for the nullable `formalRequest` sub-object. The `status`
/// string is the source of truth; the int `statusCode` is ignored on parse
/// (strings only, per the backend contract).
class CaseFormalRequestModel {
  final int id;
  final String status;

  const CaseFormalRequestModel({required this.id, required this.status});

  factory CaseFormalRequestModel.fromJson(Map<String, dynamic> json) =>
      CaseFormalRequestModel(
        id: parseInt(json['id']),
        status: parseString(json['status']),
      );

  CaseFormalRequest toEntity() => CaseFormalRequest(
        id: id,
        status: FormalRequestStatus.fromString(status),
      );
}
