import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../logic/blocs/alarm/alarm_bloc.dart';
import '../../logic/blocs/recorder/recorder_bloc.dart';
import '../../data/models/alarm_model.dart';
import 'add_alarm_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text(
              'Voice Alarms',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          BlocBuilder<AlarmBloc, AlarmState>(
            builder: (context, state) {
              if (state is AlarmLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (state is AlarmLoaded) {
                if (state.alarms.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.alarm_add_outlined,
                            size: 80,
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No alarms set yet',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final alarm = state.alarms[index];
                      return Dismissible(
                        key: ValueKey(alarm.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: const Icon(Icons.delete_rounded, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          context.read<AlarmBloc>().add(DeleteAlarm(alarm.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${alarm.title} deleted')),
                          );
                        },
                        child: AlarmCard(alarm: alarm),
                      );
                    },
                    childCount: state.alarms.length,
                  ),
                );
              } else if (state is AlarmError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Error: ${state.message}')),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddAlarmScreen()),
          );
        },
        label: const Text('Add Alarm'),
        icon: const Icon(Icons.add_rounded),
        elevation: 4,
      ),
    );
  }
}

class AlarmCard extends StatelessWidget {
  final Alarm alarm;
  const AlarmCard({super.key, required this.alarm});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm a');
    final dateFormat = DateFormat('EEE, MMM d');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AddAlarmScreen(alarm: alarm)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alarm.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeFormat.format(alarm.dateTime),
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            dateFormat.format(alarm.dateTime),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: alarm.isActive,
                      onChanged: (value) {
                        context.read<AlarmBloc>().add(ToggleAlarm(alarm.id));
                      },
                    ),
                  ],
                ),
                if (alarm.audioPath != null) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () {
                           context.read<RecorderBloc>().add(PlayRecording(alarm.audioPath!));
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                      ),
                      const SizedBox(width: 12),
                      const Text('Voice Reminder'),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                           context.read<AlarmBloc>().add(UpdateAlarm(
                             Alarm(
                               id: alarm.id,
                               title: alarm.title,
                               dateTime: alarm.dateTime,
                               audioPath: null,
                               isActive: alarm.isActive,
                               isOneTime: alarm.isOneTime,
                             ),
                           ));
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
