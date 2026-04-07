import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../logic/blocs/alarm/alarm_bloc.dart';
import '../../services/audio_service.dart';
import '../../data/models/alarm_model.dart';

class AlarmRingScreen extends StatefulWidget {
  final Alarm alarm;
  const AlarmRingScreen({super.key, required this.alarm});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen>
    with SingleTickerProviderStateMixin {
  static const _channel = MethodChannel('com.example.alarmclock/settings');
  late AnimationController _controller;
  final AudioService _audioService = AudioService();

  late DateTime _now;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();

    _channel.invokeMethod('setShowOnLockScreen').catchError((e) {
      debugPrint('setShowOnLockScreen error: $e');
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    _playAlarmSource();
  }

  Future<void> _playAlarmSource() async {
    if (widget.alarm.audioPath != null) {
      await _audioService.playRecording(widget.alarm.audioPath!);
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _controller.dispose();
    _audioService.stopPlayback();
    _audioService.dispose();
    _channel.invokeMethod('clearLockScreenFlags').catchError((e) {
      debugPrint('clearLockScreenFlags error: $e');
    });
    super.dispose();
  }

  void _dismiss() {
    context
        .read<AlarmBloc>()
        .add(UpdateAlarm(widget.alarm.copyWith(isActive: false)));
    Navigator.of(context).pop();
  }

  void _snooze() {
    final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
    context
        .read<AlarmBloc>()
        .add(UpdateAlarm(widget.alarm.copyWith(dateTime: snoozeTime)));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm');
    final amPmFormat = DateFormat('a');

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            FadeTransition(
              opacity: _controller,
              child: ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.1).animate(_controller),
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.alarm_rounded,
                    size: 100,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  timeFormat.format(_now),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  amPmFormat.format(_now),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.alarm.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Spacer(),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _snooze,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('SNOOZE (5m)',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _dismiss,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('DISMISS',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}