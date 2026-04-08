package com.example.alarmclock

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

class AlarmSoundService : Service() {

    private var ringtone: Ringtone? = null
    private var wakeLock: PowerManager.WakeLock? = null

    companion object {
        private const val NOTIF_ID = 9001
        const val CHANNEL_ID = "alarm_channel_v5"

        fun start(context: Context, payload: String?) {
            val intent = Intent(context, AlarmSoundService::class.java).apply {
                putExtra("payload", payload)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            Log.d("AlarmSoundService", "▶️ startForegroundService called")
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, AlarmSoundService::class.java))
            Log.d("AlarmSoundService", "🛑 stopService called")
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val payload = intent?.getStringExtra("payload")
        Log.d("AlarmSoundService", "🔔 Alarm service started. Payload: $payload")

        val pm = getSystemService(POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "alarmclock:ServiceWakeLock"
        ).apply { acquire(120_000L) }

        try {
            createNotificationChannel()
            val notification = buildNotification(payload)
            
            if (Build.VERSION.SDK_INT >= 34) {
                startForeground(
                    NOTIF_ID, 
                    notification, 
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SHORT_SERVICE
                )
            } else {
                startForeground(NOTIF_ID, notification)
            }

            playAlarm()

            // 🔥 FORCE LAUNCH FLUTTER UI:
            // Android 10+ blocks background launches, but ALLOWS them if the app
            // has the SYSTEM_ALERT_WINDOW (Display over other apps) permission.
            // If the user is on another app, the Head-Up notification isn't enough;
            // this forcibly pops the UI on screen.
            try {
                val forceLaunchIntent = Intent(this, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    putExtra("payload", payload)
                }
                startActivity(forceLaunchIntent)
                Log.d("AlarmSoundService", "🚀 Forced Flutter UI launch from background")
            } catch (e: Exception) {
                Log.e("AlarmSoundService", "⚠️ Forced launch blocked by OS: ${e.message}")
            }

        } catch (e: Exception) {
            Log.e("AlarmSoundService", "❌ Foreground service crash prevented: ${e.message}")
            stopSelf()
        }

        return START_NOT_STICKY // Don't restart if killed to prevent 1-minute delayed ghost alarms
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NotificationManager::class.java)
            if (nm.getNotificationChannel(CHANNEL_ID) != null) return

            val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            val audioAttr = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_ALARM)
                .build()

            val channel = NotificationChannel(
                CHANNEL_ID, "Voice Alarm Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alarm notification channel"
                setBypassDnd(true)
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 300, 500)
                setSound(alarmUri, audioAttr)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(payload: String?): android.app.Notification {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("payload", payload)
        }
        val notifId = payload?.hashCode() ?: 12345
        val launchPi = PendingIntent.getActivity(
            this, notifId, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("⏰ Voice Alarm")
            .setContentText("Tap to open your alarm")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setFullScreenIntent(launchPi, true)
            .setContentIntent(launchPi)
            .setOngoing(true)
            .setAutoCancel(false)
            .build()
    }

    private fun playAlarm() {
        try {
            val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)

            ringtone = RingtoneManager.getRingtone(applicationContext, alarmUri)
            ringtone?.audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                ringtone?.isLooping = true
            }
            ringtone?.play()
            Log.d("AlarmSoundService", "✅ Alarm sound playing")
        } catch (e: Exception) {
            Log.e("AlarmSoundService", "❌ playAlarm failed: ${e.message}")
        }
    }

    override fun onDestroy() {
        Log.d("AlarmSoundService", "🛑 Destroyed — stopping sound")
        ringtone?.stop()
        ringtone = null
        wakeLock?.release()
        wakeLock = null
        super.onDestroy()
    }
}
