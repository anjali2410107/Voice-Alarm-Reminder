import 'package:flutter/material.dart';
import '../../main.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../logic/blocs/alarm/alarm_bloc.dart';
import '../../logic/blocs/recorder/recorder_bloc.dart';
import '../../logic/blocs/recording/recording_bloc.dart';
import '../../logic/blocs/recording/recording_event.dart';
import '../../logic/blocs/recording/recording_state.dart';
import '../../data/models/alarm_model.dart';

class AddAlarmScreen extends StatefulWidget {
  final Alarm? alarm;
  const AddAlarmScreen({super.key, this.alarm});

  @override
  State<AddAlarmScreen> createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends State<AddAlarmScreen> {
  late TextEditingController _titleController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _recordedPath;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.alarm?.title ?? '');
    _selectedDate = widget.alarm?.dateTime ?? DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(_selectedDate);
    _recordedPath = widget.alarm?.audioPath;
    
    context.read<RecorderBloc>().add(ResetRecorder());
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveAlarm() {
    final combinedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final String id = widget.alarm?.id ?? const Uuid().v4();
    final Alarm newAlarm = Alarm(
      id: id,
      title: _titleController.text.isEmpty ? 'New Alarm' : _titleController.text,
      dateTime: combinedDateTime,
      audioPath: _recordedPath,
      isActive: true,
      isOneTime: true,
    );

    if (widget.alarm == null) {
      context.read<AlarmBloc>().add(AddAlarm(newAlarm));
    } else {
      context.read<AlarmBloc>().add(UpdateAlarm(newAlarm));
    }

    final duration = combinedDateTime.difference(DateTime.now());
    if (!duration.isNegative) {
      String message;
      if (duration.inHours >= 24) {
        final dateFormat = DateFormat('EEE, MMM d');
        final timeFormat = DateFormat('hh:mm a');
        message = 'Alarm set for ${dateFormat.format(combinedDateTime)} at ${timeFormat.format(combinedDateTime)}';
      } else {
        message = 'Alarm set for ${_formatDuration(duration)} from now';
      }

      messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    Navigator.of(context).pop();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    final List<String> parts = [];
    if (hours > 0) parts.add('$hours ${hours == 1 ? 'hour' : 'hours'}');
    if (minutes > 0) parts.add('$minutes ${minutes == 1 ? 'minute' : 'minutes'}');

    if (parts.isEmpty) return 'less than a minute';
    return parts.join(' and ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alarm == null ? 'New Alarm' : 'Edit Alarm'),
        actions: [
          TextButton(
            onPressed: _saveAlarm,
            child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Label',
                hintText: 'Work Meeting, Wake up...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                prefixIcon: const Icon(Icons.label_outline_rounded),
              ),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('EEE, MMM d').format(_selectedDate),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TIME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            _selectedTime.format(context),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            BlocListener<RecorderBloc, RecorderState>(
              listener: (context, state) {
                if (state.status == RecorderStatus.success) {
                  context.read<RecordingBloc>().add(LoadRecordings());
                  
                  setState(() {
                    _recordedPath = state.audioPath;
                  });
                }
              },
              child: const VoiceRecorderSection(),
            ),
          ],
        ),
      ),
    );
  }
}

class VoiceRecorderSection extends StatelessWidget {
  const VoiceRecorderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecorderBloc, RecorderState>(
      builder: (context, state) {
        return Column(
          children: [
            Text(
              'Voice Reminder',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Record a personal message to hear when the alarm rings.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 32),
            if (state.status == RecorderStatus.recording)
              _buildRecordingUI(context)
            else if (state.status == RecorderStatus.success || state.status == RecorderStatus.playing)
               _buildSuccessUI(context, state)
            else
               _buildInitialUI(context),
          ],
        );
      },
    );
  }

  Widget _buildInitialUI(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                IconButton.filled(
                  onPressed: () {
                    final fileName = 'alarm_${DateTime.now().millisecondsSinceEpoch}';
                    context.read<RecorderBloc>().add(StartRecording(fileName));
                  },
                  iconSize: 48,
                  icon: const Icon(Icons.mic_rounded),
                ),
                const SizedBox(height: 8),
                const Text('Record New', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(width: 48),
            Column(
              children: [
                IconButton.filledTonal(
                  onPressed: () => _showLibraryPicker(context),
                  iconSize: 48,
                  icon: const Icon(Icons.library_music_rounded),
                ),
                const SizedBox(height: 8),
                const Text('From Library', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _showLibraryPicker(BuildContext context) {
    final recordingBloc = context.read<RecordingBloc>();
    recordingBloc.add(LoadRecordings());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (bottomSheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Choose Recording', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            Expanded(
              child: BlocBuilder<RecordingBloc, RecordingState>(
                bloc: recordingBloc,
                builder: (context, state) {
                  if (state.recordings.isEmpty) {
                    return const Center(child: Text('No recordings found.'));
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: state.recordings.length,
                    itemBuilder: (context, index) {
                      final recording = state.recordings[index];
                      return ListTile(
                        leading: const Icon(Icons.mic_rounded),
                        title: Text(recording.name),
                        subtitle: Text(DateFormat('MMM dd, hh:mm a').format(recording.dateTime)),
                        onTap: () {
                          context.read<RecorderBloc>().add(SetRecordingPath(recording.path));
                          Navigator.pop(bottomSheetContext);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingUI(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 100,
          child: Center(
            child: LinearProgressIndicator(), 
          ),
        ),
        IconButton.filled(
          onPressed: () {
            context.read<RecorderBloc>().add(StopRecording());
          },
          iconSize: 64,
          icon: const Icon(Icons.stop_rounded),
          style: IconButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
        ),
        const SizedBox(height: 16),
        const Text('Recording...', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
      ],
    );
  }

  Widget _buildSuccessUI(BuildContext context, RecorderState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: () {
                   if (state.status == RecorderStatus.playing) {
                      context.read<RecorderBloc>().add(StopPlayback());
                   } else {
                      context.read<RecorderBloc>().add(PlayRecording(state.audioPath!));
                   }
                },
                iconSize: 32,
                icon: Icon(state.status == RecorderStatus.playing ? Icons.stop_rounded : Icons.play_arrow_rounded),
              ),
              const SizedBox(width: 24),
              IconButton.outlined(
                onPressed: () {
                   context.read<RecorderBloc>().add(ResetRecorder());
                },
                iconSize: 32,
                icon: const Icon(Icons.replay_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Voice recording saved', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
