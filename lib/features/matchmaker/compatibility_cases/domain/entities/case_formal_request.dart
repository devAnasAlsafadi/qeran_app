import 'package:equatable/equatable.dart';

import 'formal_request_status.dart';

/// A case's formal request. [id] is the `formalRequestId` the 3b status
/// POST targets. Non-null only once the case reaches the formal track
/// (photo-exchange accepted / rejected stages).
class CaseFormalRequest extends Equatable {
  final int id;
  final FormalRequestStatus status;

  const CaseFormalRequest({required this.id, required this.status});

  CaseFormalRequest copyWith({int? id, FormalRequestStatus? status}) {
    return CaseFormalRequest(
      id: id ?? this.id,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, status];
}
