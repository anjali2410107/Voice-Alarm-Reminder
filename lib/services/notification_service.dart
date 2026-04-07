import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kPendingAlarmPayloadKey = 'pending_alarm_payload';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  if (notificationResponse.payload != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPendingAlarmPayloadKey, notificationResponse.payload!);
    debugPrint('🔔 Background tap — payload saved: ${notificationResponse.payload}');
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const _channel = MethodChannel('com.example.alarmclock/settings');

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Function(String)? _onNotificationTap;

  void setOnNotificationTap(Function(String) callback) {
    _onNotificationTap = callback;
  }

  Future<void> checkPendingAlarmPayload() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = prefs.getString(kPendingAlarmPayloadKey);
    if (payload != null) {
      debugPrint('📬 Found pending alarm payload: $payload');
      await prefs.remove(kPendingAlarmPayloadKey);
      await Future.delayed(const Duration(milliseconds: 300));
      _onNotificationTap?.call(payload);
    }
  }

  Future<void> init() async {
    tz_data.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('📱 Foreground tap: ${response.payload}');
        if (response.payload != null) {
          _onNotificationTap?.call(response.payload!);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Listen for native aggressive alarm trigger
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNativePayload') {
        final payload = call.arguments as String?;
        debugPrint('🎯 Received native payload via MethodChannel: $payload');
        if (payload != null) {
          _onNotificationTap?.call(payload);
        }
      }
    });

    debugPrint('✅ Notifications initialized');

    final NotificationAppLaunchDetails? launchDetails =
        await _notifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails?.notificationResponse?.payload;
      debugPrint('🚀 App launched from notification. Payload: $payload');
      if (payload != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(kPendingAlarmPayloadKey, payload);
      }
    }
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();

      try {
        await _channel.invokeMethod('requestIgnoreBatteryOptimization');
      } on PlatformException catch (e) {
        debugPrint('Battery opt request failed: ${e.message}');
      }

      // 🕒 Critical Permissions for Reliable Alarms
      final overlay = await checkOverlayPermission();
      if (!overlay) {
        debugPrint('⚠️ Overlay permission missing — requesting at startup');
        await openOverlaySettings();
      }

      final fsi = await checkFullScreenIntentPermission();
      if (!fsi) {
        debugPrint('⚠️ Full Screen Intent permission missing — requesting at startup');
        await openFullScreenIntentSettings();
      }
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<bool> checkNotificationPermission() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  Future<bool> checkExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidImplementation?.canScheduleExactNotifications() ?? false;
    }
    return true;
  }

  Future<bool> checkOverlayPermission() async {
    if (Platform.isAndroid) {
      try {
        return await _channel.invokeMethod<bool>('checkOverlayPermission') ?? false;
      } on PlatformException {
        return false;
      }
    }
    return true;
  }

  Future<bool> checkFullScreenIntentPermission() async {
    if (Platform.isAndroid) {
      try {
        return await _channel.invokeMethod<bool>('checkFullScreenIntentPermission') ?? false;
      } on PlatformException {
        return false;
      }
    }
    return true;
  }

  Future<void> openAlarmSettings() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('openAlarmSettings');
      } on PlatformException catch (e) {
        debugPrint('Failed to open alarm settings: ${e.message}');
      }
    }
  }

  Future<void> openOverlaySettings() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('openOverlaySettings');
      } on PlatformException catch (e) {
        debugPrint('Failed to open overlay settings: ${e.message}');
      }
    }
  }

  Future<void> openFullScreenIntentSettings() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('openFullScreenIntentSettings');
      } on PlatformException catch (e) {
        debugPrint('Failed to open full screen intent settings: ${e.message}');
      }
    }
  }

  Future<void> scheduleAlarm(
      int id, String title, DateTime dateTime, String? payload) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);

    debugPrint('=== SCHEDULING ALARM ===');
    debugPrint('ID:        $id');
    debugPrint('NOW:       $now');
    debugPrint('SCHEDULED: $scheduledDate');
    debugPrint('IS PAST:   ${scheduledDate.isBefore(now)}');

    if (scheduledDate.isBefore(now)) {
      debugPrint('⚠️ Alarm skipped — scheduled time is in the past');
      return;
    }

    // 🚨 CHANNEL V3: Silent but High Importance
    // Fresh ID required to override Android's cached low-importance or sound settings.
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alarm_channel_v3',
      'Silent Alarm Notifications',
      channelDescription: 'Scheduled silent alarm reminders',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ongoing: true,
      autoCancel: false,
      ticker: 'Alarm',
      playSound: false, // 🔇 NO SYSTEM SOUND
      enableVibration: false, // 🔇 NO VIBRATION
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // 1. Standard notification (silent) — handles lock screen waking
      await _notifications.zonedSchedule(
        id: id,
        title: 'Alarm: $title',
        body: 'Wake up! Your voice reminder is ready.',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: payload,
      );

      // 2. Aggressive native launch — handles screen-on foregrounding
      await _scheduleNativeAggressiveAlarm(id, dateTime, payload);

      debugPrint('✅ Alarm scheduled successfully (Silent + Aggressive)');
    } catch (e) {
      debugPrint('❌ Failed to schedule alarm: $e');
      rethrow;
    }
  }

  Future<void> _scheduleNativeAggressiveAlarm(
      int id, DateTime dateTime, String? payload) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('scheduleAggressiveAlarm', {
          'id': id,
          'time': dateTime.millisecondsSinceEpoch,
          'payload': payload,
        });
      } catch (e) {
        debugPrint('⚠️ Native aggressive schedule failed: $e');
      }
    }
  }

  Future<void> cancelAlarm(int id) async {
    await _notifications.cancel(id: id);
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('cancelAggressiveAlarm', {'id': id});
      } catch (e) {
        debugPrint('⚠️ Native aggressive cancel failed: $e');
      }
    }
    debugPrint('Alarm $id cancelled');
  }
}