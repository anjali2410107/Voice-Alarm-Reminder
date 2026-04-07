import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data/repositories/alarm_repository.dart';
import 'logic/blocs/alarm/alarm_bloc.dart';
import 'logic/blocs/recorder/recorder_bloc.dart';
import 'logic/blocs/recording/recording_bloc.dart';
import 'logic/blocs/recording/recording_event.dart';
import 'services/audio_service.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'data/models/alarm_model.dart';
import 'presentation/screens/main_scaffold.dart';
import 'presentation/screens/alarm_ring_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();

  final audioService = AudioService();
  final alarmRepository = AlarmRepository();

  runApp(MyApp(
    alarmRepository: alarmRepository,
    notificationService: notificationService,
    audioService: audioService,
  ));
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> messengerKey =
GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatefulWidget {
  final AlarmRepository alarmRepository;
  final NotificationService notificationService;
  final AudioService audioService;

  const MyApp({
    super.key,
    required this.alarmRepository,
    required this.notificationService,
    required this.audioService,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupNotificationHandler();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.notificationService.checkPendingAlarmPayload();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('▶️ App resumed — checking for pending alarm payload');
      widget.notificationService.checkPendingAlarmPayload();
    }
  }

  void _setupNotificationHandler() {
    debugPrint('📋 Setting up notification tap handler');
    widget.notificationService.setOnNotificationTap((payload) async {
      debugPrint('🔔 onNotificationTap FIRED with payload: "$payload"');

      if (payload == null || payload.isEmpty) {
        debugPrint('⚠️ Empty payload — ignoring');
        return;
      }

      if (payload == 'test_payload') {
        debugPrint('🧪 Test payload detected — navigating to test ring screen');
        _navigateToRingScreen(
          Alarm(
            id: 'test',
            title: 'Test Voice Alarm',
            dateTime: DateTime.now(),
          ),
        );
        return;
      }

      try {
        debugPrint('🔍 Looking up alarm with id: $payload');
        final alarms = await widget.alarmRepository.getAlarms();
        debugPrint('📦 Total alarms in DB: ${alarms.length}');
        final alarm = alarms.firstWhere(
          (a) => a.id == payload,
          orElse: () => throw Exception('Alarm not found for id: $payload'),
        );
        debugPrint('✅ Found alarm: ${alarm.title}');
        _navigateToRingScreen(alarm);
      } catch (e) {
        debugPrint('❌ Alarm lookup failed: $e');
      }
    });
    debugPrint('📋 Notification tap handler registered');
  }

  void _navigateToRingScreen(Alarm alarm) {
    debugPrint('🚀 _navigateToRingScreen called for: ${alarm.title}');
    debugPrint('🔑 navigatorKey.currentState: ${navigatorKey.currentState}');

    void doNavigate() {
      final nav = navigatorKey.currentState;
      if (nav == null) {
        debugPrint('❌ Navigator not ready yet — retrying in 500ms');
        Future.delayed(const Duration(milliseconds: 500), doNavigate);
        return;
      }
      debugPrint('✅ Navigating to AlarmRingScreen');
      nav.push(
        MaterialPageRoute(builder: (_) => AlarmRingScreen(alarm: alarm)),
      );
    }

    doNavigate();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.audioService),
        RepositoryProvider.value(value: widget.notificationService),
        RepositoryProvider.value(value: widget.alarmRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AlarmBloc>(
            create: (context) => AlarmBloc(
              repository: widget.alarmRepository,
              notificationService: widget.notificationService,
            )..add(LoadAlarms()),
          ),
          BlocProvider<RecorderBloc>(
            create: (context) =>
                RecorderBloc(audioService: widget.audioService),
          ),
          BlocProvider<RecordingBloc>(
            create: (context) => RecordingBloc(
              databaseService: DatabaseService(),
            )..add(LoadRecordings()),
          ),
        ],
        child: MaterialApp(
        title: 'Voice Alarm Reminder',
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: messengerKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.outfitTextTheme(),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        home: const MainScaffold(),
      ),
    ),
   );
  }
}