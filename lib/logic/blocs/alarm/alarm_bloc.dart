import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/alarm_model.dart';
import '../../../data/repositories/alarm_repository.dart';
import '../../../services/notification_service.dart';

part 'alarm_event.dart';
part 'alarm_state.dart';

class AlarmBloc extends Bloc<AlarmEvent, AlarmState> {
  final AlarmRepository _repository;
  final NotificationService _notificationService;

  AlarmBloc({
    required AlarmRepository repository,
    required NotificationService notificationService,
  })  : _repository = repository,
        _notificationService = notificationService,
        super(AlarmInitial()) {
    on<LoadAlarms>(_onLoadAlarms);
    on<AddAlarm>(_onAddAlarm);
    on<UpdateAlarm>(_onUpdateAlarm);
    on<DeleteAlarm>(_onDeleteAlarm);
    on<ToggleAlarm>(_onToggleAlarm);
  }

  Future<void> _onLoadAlarms(LoadAlarms event, Emitter<AlarmState> emit) async {
    emit(AlarmLoading());
    try {
      final alarms = await _repository.getAlarms();
      emit(AlarmLoaded(alarms));
    } catch (e) {
      emit(AlarmError(e.toString()));
    }
  }

  Future<void> _onAddAlarm(AddAlarm event, Emitter<AlarmState> emit) async {
    try {
      await _repository.addAlarm(event.alarm);
      if (event.alarm.isActive) {
        await _notificationService.scheduleAlarm(
          event.alarm.id.hashCode,
          event.alarm.title,
          event.alarm.dateTime,
          event.alarm.audioPath,
        );
      }
      add(LoadAlarms());
    } catch (e) {
      emit(AlarmError(e.toString()));
    }
  }

  Future<void> _onUpdateAlarm(UpdateAlarm event, Emitter<AlarmState> emit) async {
    try {
      await _repository.updateAlarm(event.alarm);
      await _notificationService.cancelAlarm(event.alarm.id.hashCode);
      if (event.alarm.isActive) {
        await _notificationService.scheduleAlarm(
          event.alarm.id.hashCode,
          event.alarm.title,
          event.alarm.dateTime,
          event.alarm.audioPath,
        );
      }
      add(LoadAlarms());
    } catch (e) {
      emit(AlarmError(e.toString()));
    }
  }

  Future<void> _onDeleteAlarm(DeleteAlarm event, Emitter<AlarmState> emit) async {
    try {
      await _repository.deleteAlarm(event.id);
      await _notificationService.cancelAlarm(event.id.hashCode);
      add(LoadAlarms());
    } catch (e) {
      emit(AlarmError(e.toString()));
    }
  }

  Future<void> _onToggleAlarm(ToggleAlarm event, Emitter<AlarmState> emit) async {
    try {
      final currentState = state;
      if (currentState is AlarmLoaded) {
        final alarm = currentState.alarms.firstWhere((a) => a.id == event.id);
        final updatedAlarm = alarm.copyWith(isActive: !alarm.isActive);
        await _repository.updateAlarm(updatedAlarm);
        
        if (updatedAlarm.isActive) {
          await _notificationService.scheduleAlarm(
            updatedAlarm.id.hashCode,
            updatedAlarm.title,
            updatedAlarm.dateTime,
            updatedAlarm.audioPath,
          );
        } else {
          await _notificationService.cancelAlarm(updatedAlarm.id.hashCode);
        }
        add(LoadAlarms());
      }
    } catch (e) {
      emit(AlarmError(e.toString()));
    }
  }
}
