part of 'recorder_bloc.dart';

abstract class RecorderEvent extends Equatable {
  const RecorderEvent();

  @override
  List<Object?> get props => [];
}

class StartRecording extends RecorderEvent {
  final String fileName;
  const StartRecording(this.fileName);

  @override
  List<Object?> get props => [fileName];
}

class StopRecording extends RecorderEvent {}

class PlayRecording extends RecorderEvent {
  final String path;
  const PlayRecording(this.path);

  @override
  List<Object?> get props => [path];
}

class StopPlayback extends RecorderEvent {}

class ResetRecorder extends RecorderEvent {}

class SetRecordingPath extends RecorderEvent {
  final String path;
  const SetRecordingPath(this.path);

  @override
  List<Object?> get props => [path];
}
