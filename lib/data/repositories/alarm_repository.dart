import '../models/alarm_model.dart';
import '../../services/database_service.dart';

class AlarmRepository {
  final DatabaseService _databaseService;

  AlarmRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService();

  Future<void> addAlarm(Alarm alarm) async {
    await _databaseService.insertAlarm(alarm);
  }

  Future<List<Alarm>> getAlarms() async {
    return await _databaseService.getAlarms();
  }

  Future<void> updateAlarm(Alarm alarm) async {
    await _databaseService.updateAlarm(alarm);
  }

  Future<void> deleteAlarm(String id) async {
    await _databaseService.deleteAlarm(id);
  }
}
