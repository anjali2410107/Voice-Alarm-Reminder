part of 'recorder_bloc.dart';

enum RecorderStatus { initial, recording, success, playing, error }

class RecorderState extends Equatable {
  final RecorderStatus status;
  final String? audioPath;
  final String? message;

  const RecorderState({
    this.status = RecorderStatus.initial,
    this.audioPath,
    this.message,
  });

  RecorderState copyWith({
    RecorderStatus? status,
    String? audioPath,
    String? message,
  }) {
    return RecorderState(
      status: status ?? this.status,
      audioPath: audioPath ?? this.audioPath,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, audioPath, message];
}
