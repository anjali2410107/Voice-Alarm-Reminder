import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/database_service.dart';
import '../../../data/models/recording_model.dart';
import 'package:uuid/uuid.dart';
import 'recording_event.dart';
import 'recording_state.dart';
import 'dart:io';

class RecordingBloc extends Bloc<RecordingEvent, RecordingState> {
  final DatabaseService _databaseService;

  RecordingBloc({required DatabaseService databaseService})
      : _databaseService = databaseService,
        super(const RecordingState()) {
    on<LoadRecordings>(_onLoadRecordings);
    on<AddRecording>(_onAddRecording);
    on<DeleteRecording>(_onDeleteRecording);
  }

  Future<void> _onLoadRecordings(LoadRecordings event, Emitter<RecordingState> emit) async {
    emit(state.copyWith(status: RecordingStatus.loading));
    try {
      final recordings = await _databaseService.getRecordings();
      emit(state.copyWith(status: RecordingStatus.success, recordings: recordings));
    } catch (e) {
      emit(state.copyWith(status: RecordingStatus.error, message: e.toString()));
    }
  }

  Future<void> _onAddRecording(AddRecording event, Emitter<RecordingState> emit) async {
    try {
      final recording = Recording(
        id: const Uuid().v4(),
        name: event.name,
        path: event.path,
        dateTime: DateTime.now(),
      );
      await _databaseService.insertRecording(recording);
      add(LoadRecordings());
    } catch (e) {
      emit(state.copyWith(status: RecordingStatus.error, message: e.toString()));
    }
  }

  Future<void> _onDeleteRecording(DeleteRecording event, Emitter<RecordingState> emit) async {
    try {
      // 1. Find the recording to get the path
      final recording = state.recordings.firstWhere((r) => r.id == event.id);
      
      // 2. Delete physical file
      final file = File(recording.path);
      if (await file.exists()) {
        await file.delete();
      }

      // 3. Delete from DB
      await _databaseService.deleteRecording(event.id);
      add(LoadRecordings());
    } catch (e) {
      emit(state.copyWith(status: RecordingStatus.error, message: e.toString()));
    }
  }
}
