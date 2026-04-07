import 'package:equatable/equatable.dart';
import '../../../data/models/recording_model.dart';

enum RecordingStatus { initial, loading, success, error }

class RecordingState extends Equatable {
  final List<Recording> recordings;
  final RecordingStatus status;
  final String? message;

  const RecordingState({
    this.recordings = const [],
    this.status = RecordingStatus.initial,
    this.message,
  });

  RecordingState copyWith({
    List<Recording>? recordings,
    RecordingStatus? status,
    String? message,
  }) {
    return RecordingState(
      recordings: recordings ?? this.recordings,
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [recordings, status, message];
}
