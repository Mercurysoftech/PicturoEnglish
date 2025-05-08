package com.picturoenglish.picturo

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
        private const val PREFS_NAME = "PicturoPrefs"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "Device boot completed, rescheduling notifications")
            rescheduleNotifications(context)
        }
    }

    private fun rescheduleNotifications(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val morningHour = prefs.getInt("morning_hour", -1)
        val morningMinute = prefs.getInt("morning_minute", -1)
        val eveningHour = prefs.getInt("evening_hour", -1)
        val eveningMinute = prefs.getInt("evening_minute", -1)

        if (morningHour != -1 && morningMinute != -1) {
            scheduleNotification(
                context,
                morningHour,
                morningMinute,
                NotificationConstants.morningNotificationId,
                "morning_picturo_channel",
                "Morning Reminder",
                "Time for your morning practice!"
            )
        }

        if (eveningHour != -1 && eveningMinute != -1) {
            scheduleNotification(
                context,
                eveningHour,
                eveningMinute,
                NotificationConstants.eveningNotificationId,
                "evening_picturo_channel",
                "Evening Reminder",
                "Time for your evening practice!"
            )
        }
    }

    private fun scheduleNotification(
        context: Context,
        hour: Int,
        minute: Int,
        notificationId: Int,
        channelId: String,
        title: String,
        body: String
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("notification_id", notificationId)
            putExtra("channel_id", channelId)
            putExtra("title", title)
            putExtra("body", body)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            notificationId,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val calendar = java.util.Calendar.getInstance().apply {
            set(java.util.Calendar.HOUR_OF_DAY, hour)
            set(java.util.Calendar.MINUTE, minute)
            set(java.util.Calendar.SECOND, 0)
            
            if (timeInMillis <= System.currentTimeMillis()) {
                add(java.util.Calendar.DAY_OF_YEAR, 1)
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                calendar.timeInMillis,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                calendar.timeInMillis,
                pendingIntent
            )
        }

        Log.d(TAG, "Notification $notificationId scheduled for ${calendar.time}")
    }
}