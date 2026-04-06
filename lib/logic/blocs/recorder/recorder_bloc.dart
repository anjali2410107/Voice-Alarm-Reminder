import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../services/audio_service.dart';

part 'recorder_event.dart';
part 'recorder_state.dart';

class RecorderBloc extends Bloc<RecorderEvent, RecorderState> {
  final AudioService _audioService;

  RecorderBloc({required AudioService audioService})
      : _audioService = audioService,
        super(const RecorderState()) {
    on<StartRecording>(_onStartRecording);
    on<StopRecording>(_onStopRecording);
    on<PlayRecording>(_onPlayRecording);
    on<StopPlayback>(_onStopPlayback);
    on<ResetRecorder>(_onResetRecorder);
  }

  Future<void> _onStartRecording(StartRecording event, Emitter<RecorderState> emit) async {
    try {
      final success = await _audioService.startRecording(event.fileName);
      if (success) {
        emit(state.copyWith(status: RecorderStatus.recording));
      } else {
        emit(state.copyWith(status: RecorderStatus.error, message: 'Permission denied'));
      }
    } catch (e) {
      emit(state.copyWith(status: RecorderStatus.error, message: e.toString()));
    }
  }

  Future<void> _onStopRecording(StopRecording event, Emitter<RecorderState> emit) async {
    try {
      final path = await _audioService.stopRecording();
      if (path != null) {
        emit(state.copyWith(status: RecorderStatus.success, audioPath: path));
      }
    } catch (e) {
      emit(state.copyWith(status: RecorderStatus.error, message: e.toString()));
    }
  }

  Future<void> _onPlayRecording(PlayRecording event, Emitter<RecorderState> emit) async {
    try {
      await _audioService.playRecording(event.path);
      emit(state.copyWith(status: RecorderStatus.playing));
    } catch (e) {
      emit(state.copyWith(status: RecorderStatus.error, message: e.toString()));
    }
  }

  Future<void> _onStopPlayback(StopPlayback event, Emitter<RecorderState> emit) async {
    try {
      await _audioService.stopPlayback();
      emit(state.copyWith(status: RecorderStatus.success));
    } catch (e) {
      emit(state.copyWith(status: RecorderStatus.error, message: e.toString()));
    }
  }

  void _onResetRecorder(ResetRecorder event, Emitter<RecorderState> emit) {
    emit(const RecorderState());
  }
}
