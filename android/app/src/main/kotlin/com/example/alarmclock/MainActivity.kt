package com.example.alarmclock

import android.app.KeyguardManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.alarmclock/settings"
    private var wakeLock: PowerManager.WakeLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // ── Lock screen overlay ─────────────────────────────────
                    "setShowOnLockScreen" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                            // Modern API (Android 8.1+)
                            setShowWhenLocked(true)
                            setTurnScreenOn(true)
                            val km = getSystemService(KEYGUARD_SERVICE) as KeyguardManager
                            km.requestDismissKeyguard(this, null)
                        } else {
                            // Legacy flags
                            @Suppress("DEPRECATION")
                            window.addFlags(
                                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                            )
                        }
                        // Keep screen on while alarm is ringing
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        // Acquire wake lock so CPU stays awake
                        val pm = getSystemService(POWER_SERVICE) as PowerManager
                        wakeLock?.release()
                        wakeLock = pm.newWakeLock(
                            PowerManager.FULL_WAKE_LOCK or
                            PowerManager.ACQUIRE_CAUSES_WAKEUP or
                            PowerManager.ON_AFTER_RELEASE,
                            "alarmclock:AlarmWakeLock"
                        ).also { it.acquire(60_000L) } // 60s max
                        result.success(null)
                    }

                    "clearLockScreenFlags" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                            setShowWhenLocked(false)
                            setTurnScreenOn(false)
                        } else {
                            @Suppress("DEPRECATION")
                            window.clearFlags(
                                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                            )
                        }
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        wakeLock?.release()
                        wakeLock = null
                        result.success(null)
                    }

                    // ── Existing methods ────────────────────────────────────
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

    override fun onDestroy() {
        super.onDestroy()
        wakeLock?.release()
        wakeLock = null
    }
}