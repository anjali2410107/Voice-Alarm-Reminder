import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../logic/blocs/recording/recording_bloc.dart';
import '../../logic/blocs/recording/recording_event.dart';
import '../../logic/blocs/recording/recording_state.dart';
import '../../services/audio_service.dart';
import '../../data/models/recording_model.dart';

class RecordingsLibraryScreen extends StatefulWidget {
  const RecordingsLibraryScreen({super.key});

  @override
  State<RecordingsLibraryScreen> createState() => _RecordingsLibraryScreenState();
}

class _RecordingsLibraryScreenState extends State<RecordingsLibraryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RecordingBloc>().add(LoadRecordings());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final audioService = context.read<AudioService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Library'),
        centerTitle: true,
      ),
      body: BlocBuilder<RecordingBloc, RecordingState>(
        builder: (context, state) {
          if (state.status == RecordingStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.recordings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mic_none_rounded,
                    size: 80,
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recordings yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Record something when adding an alarm!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: state.recordings.length,
            itemBuilder: (context, index) {
              final recording = state.recordings[index];
              return _RecordingCard(
                recording: recording,
                audioService: audioService,
              );
            },
          );
        },
      ),
    );
  }
}

class _RecordingCard extends StatefulWidget {
  final Recording recording;
  final AudioService audioService;

  const _RecordingCard({
    required this.recording,
    required this.audioService,
  });

  @override
  State<_RecordingCard> createState() => _RecordingCardState();
}

class _RecordingCardState extends State<_RecordingCard> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(widget.recording.dateTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.mic_rounded,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          widget.recording.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(dateStr),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.stop_circle_rounded : Icons.play_circle_filled_rounded,
                color: theme.colorScheme.primary,
                size: 32,
              ),
              onPressed: () async {
                if (_isPlaying) {
                  await widget.audioService.stopPlayback();
                  setState(() => _isPlaying = false);
                } else {
                  setState(() => _isPlaying = true);
                  await widget.audioService.playRecording(widget.recording.path);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: () => _showDeleteDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Recording?'),
        content: const Text('This will permanently remove the audio file. It will not delete alarms using this recording, but they may fail to ring.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<RecordingBloc>().add(DeleteRecording(widget.recording.id));
              Navigator.pop(dialogContext);
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}
