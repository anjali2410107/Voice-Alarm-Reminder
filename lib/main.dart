import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data/repositories/alarm_repository.dart';
import 'logic/blocs/alarm/alarm_bloc.dart';
import 'logic/blocs/recorder/recorder_bloc.dart';
import 'services/audio_service.dart';
import 'services/notification_service.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/main_scaffold.dart';
import 'presentation/screens/alarm_ring_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final notificationService = NotificationService();
  await notificationService.init();
  
  final audioService = AudioService();
  final alarmRepository = AlarmRepository();

  runApp(MyApp(
    alarmRepository: alarmRepository,
    notificationService: notificationService,
    audioService: audioService,
  ));
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupNotificationHandler();
  }

  void _setupNotificationHandler() {
    widget.notificationService.setOnNotificationTap((payload) async {
        final alarms = await widget.alarmRepository.getAlarms();
       try {
         final alarm = alarms.firstWhere((a) => a.audioPath == payload || a.id == payload);
         navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => AlarmRingScreen(alarm: alarm))
         );
       } catch (e) {
         debugPrint('Alarm not found for payload: $payload');
       }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AlarmBloc>(
          create: (context) => AlarmBloc(
            repository: widget.alarmRepository,
            notificationService: widget.notificationService,
          )..add(LoadAlarms()),
        ),
        BlocProvider<RecorderBloc>(
          create: (context) => RecorderBloc(audioService: widget.audioService),
        ),
      ],
      child: MaterialApp(
        title: 'Voice Alarm Reminder',
        navigatorKey: navigatorKey,
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
    );
  }
}
