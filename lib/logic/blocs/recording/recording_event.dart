import 'package:equatable/equatable.dart';

abstract class RecordingEvent extends Equatable {
  const RecordingEvent();

  @override
  List<Object?> get props => [];
}

class LoadRecordings extends RecordingEvent {}

class AddRecording extends RecordingEvent {
  final String name;
  final String path;

  const AddRecording({required this.name, required this.path});

  @override
  List<Object?> get props => [name, path];
}

class DeleteRecording extends RecordingEvent {
  final String id;

  const DeleteRecording(this.id);

  @override
  List<Object?> get props => [id];
}
