package com.example.alarmclock

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.util.Log

class AlarmTriggerReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val payload = intent.getStringExtra("payload")
        Log.d("AlarmTriggerReceiver", "🔔 Alarm triggered natively! Payload: $payload")

        // Acquire a temporary WakeLock so the CPU doesn't fall back asleep
        // while we are trying to start the activity.
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = pm.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
            "alarmclock:BroadcastWakeLock"
        ).apply { 
            acquire(10_000L) 
        }

        // Construct intent to launch MainActivity
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            // Crucial flags for lock screen bypass
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            // Pass the payload so Flutter knows which alarm to show
            putExtra("payload", payload)
        }

        try {
            context.startActivity(launchIntent)
            Log.d("AlarmTriggerReceiver", "🚀 Started MainActivity from background")
        } catch (e: Exception) {
            Log.e("AlarmTriggerReceiver", "❌ Failed to start activity: ${e.message}")
        }
    }
}
