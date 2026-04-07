import 'dart:async';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class AudioService {
  final _record = AudioRecorder();
  final _player = AudioPlayer();
  
  bool _isPlayerInit = false;

  Future<bool> startRecording(String fileName) async {
    if (await _record.hasPermission()) {
      final appDocDir = await getApplicationDocumentsDirectory();
      final filePath = p.join(appDocDir.path, '$fileName.m4a');
      
      const config = RecordConfig();
      await _record.start(config, path: filePath);
      return true;
    }
    return false;
  }

  Future<String?> stopRecording() async {
    final path = await _record.stop();
    return path;
  }

  /// Plays a custom voice recording FROM local storage
  Future<void> playRecording(String path) async {
    if (!_isPlayerInit) {
      _isPlayerInit = true;
    }
    await _player.play(DeviceFileSource(path));
  }

  /// Plays the phone's native default ALARM sound as a fallback
  Future<void> playDefaultAlarm() async {
    await FlutterRingtonePlayer().playAlarm(
      looping: true,
      asAlarm: true, 
      volume: 1.0,
    );
  }

  /// Stops ALL sound (both custom recordings and system alarm)
  Future<void> stopPlayback() async {
    await _player.stop();
    await FlutterRingtonePlayer().stop();
  }

  Future<void> dispose() async {
    await _record.dispose();
    await _player.dispose();
    await FlutterRingtonePlayer().stop();
  }

  Stream<RecordState> get recorderState => _record.onStateChanged();
  Stream<PlayerState> get playerState => _player.onPlayerStateChanged;
}
