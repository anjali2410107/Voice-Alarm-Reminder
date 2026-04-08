package com.example.alarmclock

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.util.Log

class AlarmTriggerReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val payload = intent.getStringExtra("payload")
        Log.d("AlarmTriggerReceiver", "🔔 Alarm triggered! Payload: $payload")

        // 1. Save payload to SharedPreferences — Flutter reads this on cold start
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit().putString("flutter.pending_alarm_payload", payload).apply()

        // 2. Send an ordered broadcast. If the app is OPEN, MainActivity handles it
        //    and sets resultCode to RESULT_OK. If the app is CLOSED, it falls back
        //    to starting the native foreground service.
        val localBroadcast = Intent("com.example.alarmclock.ALARM_TRIGGER").apply {
            putExtra("payload", payload)
            setPackage(context.packageName) // Only delivered to our own app
        }
        
        context.sendOrderedBroadcast(localBroadcast, null, object : BroadcastReceiver() {
            override fun onReceive(ctx: Context, intent: Intent) {
                if (resultCode != android.app.Activity.RESULT_OK) {
                    // Flutter did not handle it (app is closed or in background).
                    // Start the native service.
                    val pm = ctx.getSystemService(Context.POWER_SERVICE) as PowerManager
                    val wakeLock = pm.newWakeLock(
                        PowerManager.PARTIAL_WAKE_LOCK,
                        "alarmclock:ReceiverWakeLock"
                    ).apply { acquire(5_000L) }

                    try {
                        AlarmSoundService.start(ctx, payload)
                        Log.d("AlarmTriggerReceiver", "✅ App offline — AlarmSoundService started")
                    } catch (e: Exception) {
                        Log.e("AlarmTriggerReceiver", "❌ Failed to start service: ${e.message}")
                    } finally {
                        wakeLock.release()
                    }
                } else {
                    Log.d("AlarmTriggerReceiver", "👍 App is open — Flutter is playing the alarm audio.")
                }
            }
        }, null, android.app.Activity.RESULT_CANCELED, null, null)
    }
}
