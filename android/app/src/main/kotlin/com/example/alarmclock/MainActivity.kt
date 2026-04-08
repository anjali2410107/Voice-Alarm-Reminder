package com.example.alarmclock

import android.app.AlarmManager
import android.app.KeyguardManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import android.content.BroadcastReceiver
import android.content.IntentFilter
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.alarmclock/settings"
    private var wakeLock: PowerManager.WakeLock? = null
    private var isAppInForeground = false

    // Catch alarm triggers when the app is already open in the foreground
    private val localAlarmReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            // Only intercept if the app is actively on screen
            if (intent.action == "com.example.alarmclock.ALARM_TRIGGER" && isAppInForeground) {
                // Signal to AlarmTriggerReceiver that we are handling it in Flutter
                // so it doesn't start the native default alarm sound
                resultCode = android.app.Activity.RESULT_OK 
                
                val payload = intent.getStringExtra("payload")
                Log.d("MainActivity", "📬 Local broadcast payload received while app is OPEN: $payload")
                flutterEngine?.dartExecutor?.binaryMessenger?.let {
                    MethodChannel(it, CHANNEL).invokeMethod("onNativePayload", payload)
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        configureFlags()
        handleIntent(intent)
        
        // Register receiver for foreground alarm triggers
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(localAlarmReceiver, IntentFilter("com.example.alarmclock.ALARM_TRIGGER"), Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(localAlarmReceiver, IntentFilter("com.example.alarmclock.ALARM_TRIGGER"))
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        wakeLock?.release()
        wakeLock = null
        try {
            unregisterReceiver(localAlarmReceiver)
        } catch (e: Exception) {
            // Ignore if not registered
        }
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        configureFlags()
    }

    override fun onResume() {
        super.onResume()
        isAppInForeground = true
        configureFlags()
    }

    override fun onPause() {
        super.onPause()
        isAppInForeground = false
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        configureFlags()
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val payload = intent?.getStringExtra("payload")
        if (payload != null) {
            Log.d("MainActivity", "📬 Native intent payload received: $payload")
            // 1. Save to SharedPreferences for cold starts
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            prefs.edit().putString("flutter.pending_alarm_payload", payload).apply()

            // 2. Notify Flutter immediately if engine is ready
            flutterEngine?.dartExecutor?.binaryMessenger?.let {
                MethodChannel(it, CHANNEL).invokeMethod("onNativePayload", payload)
            }
        }
    }

    private fun configureFlags() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }

        // Apply legacy flags simultaneously for maximum device compatibility
        @Suppress("DEPRECATION")
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "setShowOnLockScreen" -> {
                        configureFlags()
                        // Acquire wake lock for 60s
                        val pm = getSystemService(POWER_SERVICE) as PowerManager
                        wakeLock?.release()
                        wakeLock = pm.newWakeLock(
                            PowerManager.FULL_WAKE_LOCK or
                            PowerManager.ACQUIRE_CAUSES_WAKEUP or
                            PowerManager.ON_AFTER_RELEASE,
                            "alarmclock:AlarmWakeLock"
                        ).also { it.acquire(60_000L) }
                        result.success(null)
                    }

                    "scheduleAggressiveAlarm" -> {
                        val id = call.argument<Int>("id")!!
                        val timeMs = call.argument<Long>("time")!!
                        val payload = call.argument<String>("payload")
                        
                        val am = getSystemService(ALARM_SERVICE) as AlarmManager
                        val intent = Intent(this, AlarmTriggerReceiver::class.java).apply {
                            putExtra("payload", payload)
                        }
                        
                        val pi = PendingIntent.getBroadcast(
                            this, id, intent, 
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        
                        // 🔥 Universal Aggressive Scheduling: use setAlarmClock for ALL versions (API 21+)
                        // This is the most reliable way to wake up the system from deep sleep.
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            if (am.canScheduleExactAlarms()) {
                                am.setAlarmClock(AlarmManager.AlarmClockInfo(timeMs, pi), pi)
                            } else {
                                // Fallback for when "Exact Alarm" setting is disabled by user
                                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMs, pi)
                            }
                        } else {
                            // Legacy reliable method
                            am.setAlarmClock(AlarmManager.AlarmClockInfo(timeMs, pi), pi)
                        }
                        Log.d("MainActivity", "✅ Scheduled Aggressive Alarm $id at $timeMs")
                        result.success(null)
                    }

                    "stopAlarmService" -> {
                        AlarmSoundService.stop(this)
                        result.success(null)
                    }

                    "cancelAggressiveAlarm" -> {
                        val id = call.argument<Int>("id")!!
                        val am = getSystemService(ALARM_SERVICE) as AlarmManager
                        val intent = Intent(this, AlarmTriggerReceiver::class.java)
                        val pi = PendingIntent.getBroadcast(
                            this, id, intent, 
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        am.cancel(pi)
                        Log.d("MainActivity", "🚫 Cancelled Aggressive Alarm $id")
                        result.success(null)
                    }

                    // ── Other permissions unchanged ──
                    "checkOverlayPermission" -> result.success(
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                            Settings.canDrawOverlays(this) else true
                    )

                    "openOverlaySettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            startActivity(
                                Intent(
                                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                    Uri.parse("package:$packageName")
                                )
                            )
                        }
                        result.success(null)
                    }

                    "openAlarmSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM))
                        }
                        result.success(null)
                    }

                    "checkFullScreenIntentPermission" -> {
                        if (Build.VERSION.SDK_INT >= 34) {
                            val nm = getSystemService(NOTIFICATION_SERVICE)
                                    as android.app.NotificationManager
                            result.success(nm.canUseFullScreenIntent())
                        } else {
                            result.success(true)
                        }
                    }

                    "openFullScreenIntentSettings" -> {
                        if (Build.VERSION.SDK_INT >= 34) {
                            startActivity(
                                Intent(
                                    "android.settings.MANAGE_APP_USE_FULL_SCREEN_INTENTS",
                                    Uri.parse("package:$packageName")
                                )
                            )
                        }
                        result.success(null)
                    }

                    "requestIgnoreBatteryOptimization" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val pm = getSystemService(POWER_SERVICE) as PowerManager
                            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                                startActivity(
                                    Intent(
                                        Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                        Uri.parse("package:$packageName")
                                    )
                                )
                            }
                        }
                        result.success(null)
                    }

                    "checkBatteryOptimization" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val pm = getSystemService(POWER_SERVICE) as PowerManager
                            result.success(pm.isIgnoringBatteryOptimizations(packageName))
                        } else {
                            result.success(true)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

}