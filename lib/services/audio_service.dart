import 'dart:async';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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

  Future<void> playRecording(String path) async {
    if (!_isPlayerInit) {
      _isPlayerInit = true;
    }
    await _player.play(DeviceFileSource(path));
  }

  Future<void> stopPlayback() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    await _record.dispose();
    await _player.dispose();
  }

  Stream<RecordState> get recorderState => _record.onStateChanged();
  Stream<PlayerState> get playerState => _player.onPlayerStateChanged;
}
