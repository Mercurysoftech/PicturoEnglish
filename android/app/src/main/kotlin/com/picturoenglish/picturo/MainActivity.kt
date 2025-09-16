package com.picturoenglish.picturo

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "picturo_notifications"
    private val PREFS_NAME = "PicturoPrefs"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            when (call.method) {
                "scheduleDailyNotifications" -> {
                    val morningHour = call.argument<Int>("morningHour") ?: 9
                    val morningMinute = call.argument<Int>("morningMinute") ?: 0
                    val eveningHour = call.argument<Int>("eveningHour") ?: 18
                    val eveningMinute = call.argument<Int>("eveningMinute") ?: 53

                    val morningTitle = call.argument<String>("morningTitle") ?: "Morning Reminder"
                    val morningBody =
                            call.argument<String>("morningBody")
                                    ?: "Time for your morning practice!"
                    val eveningTitle = call.argument<String>("eveningTitle") ?: "Evening Reminder"
                    val eveningBody =
                            call.argument<String>("eveningBody")
                                    ?: "Time for your evening practice!"

                    scheduleNotifications(
                            morningHour,
                            morningMinute,
                            eveningHour,
                            eveningMinute,
                            morningTitle,
                            morningBody,
                            eveningTitle,
                            eveningBody
                    )
                    result.success(true)
                }
                "cancelAllNotifications" -> {
                    cancelAllNotifications()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun scheduleNotifications(
            morningHour: Int,
            morningMinute: Int,
            eveningHour: Int,
            eveningMinute: Int,
            morningTitle: String,
            morningBody: String,
            eveningTitle: String,
            eveningBody: String
    ) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().apply {
            putInt("morning_hour", morningHour)
            putInt("morning_minute", morningMinute)
            putInt("evening_hour", eveningHour)
            putInt("evening_minute", eveningMinute)
            apply()
        }

        scheduleSingleNotification(
                morningHour,
                morningMinute,
                NotificationConstants.morningNotificationId,
                "morning_picturo_channel",
                morningTitle,
                morningBody
        )

        scheduleSingleNotification(
                eveningHour,
                eveningMinute,
                NotificationConstants.eveningNotificationId,
                "evening_picturo_channel",
                eveningTitle,
                eveningBody
        )
    }

    private fun scheduleSingleNotification(
            hour: Int,
            minute: Int,
            notificationId: Int,
            channelId: String,
            title: String,
            body: String
    ) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent =
                Intent(this, AlarmReceiver::class.java).apply {
                    putExtra("notification_id", notificationId)
                    putExtra("channel_id", channelId)
                    putExtra("title", title)
                    putExtra("body", body)
                }

        val pendingIntent =
                PendingIntent.getBroadcast(
                        this,
                        notificationId,
                        intent,
                        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                )

        val calendar =
                java.util.Calendar.getInstance().apply {
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
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent)
        }
    }

    private fun cancelAllNotifications() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().clear().apply()

        cancelNotification(NotificationConstants.morningNotificationId)
        cancelNotification(NotificationConstants.eveningNotificationId)
    }

    private fun cancelNotification(notificationId: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AlarmReceiver::class.java)
        val pendingIntent =
                PendingIntent.getBroadcast(
                        this,
                        notificationId,
                        intent,
                        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_NO_CREATE
                )
        pendingIntent?.let {
            alarmManager.cancel(it)
            it.cancel()
        }
    }
}
