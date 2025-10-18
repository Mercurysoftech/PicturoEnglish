package com.picturo.picturoenglish

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "picturo_notifications"
    private val CALL_SERVICE_CHANNEL = "picturo_call_service"
    private val PREFS_NAME = "PicturoPrefs"

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIncomingIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        createNotificationChannel()
        handleIncomingIntent()
    }

    private fun log(message: String) {
        Log.d("MainActivity", message)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val callChannel =
                    NotificationChannel(
                                    CallForegroundService.CHANNEL_ID,
                                    "Ongoing Call",
                                    NotificationManager.IMPORTANCE_LOW
                            )
                            .apply {
                                description = "Ongoing call notifications"
                                setShowBadge(false)
                                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                                setSound(null, null)
                            }

            val notificationManager =
                    getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(callChannel)
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Notification methods
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

        // Call service methods
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_SERVICE_CHANNEL)
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "startCallService" -> {
                            val callerName = call.argument<String>("callerName") ?: "Unknown"
                            val targetUserId = call.argument<String>("targetUserId") ?: "0"
                            val isVideoCall = call.argument<Boolean>("isVideoCall") ?: false
                            startCallForegroundService(callerName, isVideoCall, targetUserId)
                            result.success(true)
                        }
                        "stopCallService" -> {
                            stopCallForegroundService()
                            result.success(true)
                        }
                        "toggleCallMute" -> {
                            val isMuted = call.argument<Boolean>("isMuted") ?: false
                            toggleCallMute(isMuted)
                            result.success(true)
                        }
                        "updateCallDuration" -> {
                            val duration = call.argument<String>("duration") ?: "00:00"
                            updateCallDuration(duration)
                            result.success(true)
                        }
                        "callConnected" -> {
                            callConnected()
                            result.success(true)
                        }
                        "callDisconnected" -> {
                            callDisconnected()
                            result.success(true)
                        }
                        "isCallServiceRunning" -> {
                            result.success(isCallServiceRunning())
                        }
                        "getPendingCallData" -> {
                            val prefs =
                                    getSharedPreferences("picturo_call_data", Context.MODE_PRIVATE)
                            val hasPendingCall = prefs.getBoolean("has_pending_call", false)

                            if (hasPendingCall) {
                                val data =
                                        mapOf(
                                                "has_pending_call" to true,
                                                "caller_name" to
                                                        prefs.getString("caller_name", "Unknown"),
                                                "caller_id" to prefs.getString("caller_id", "0"),
                                                "is_video_call" to
                                                        prefs.getBoolean("is_video_call", false)
                                        )
                                // Clear the data after reading
                                prefs.edit().clear().apply()
                                result.success(data)
                            } else {
                                result.success(null)
                            }
                        }
                        "getInitialIntent" -> {
                            val intent = getIntent()
                            val data = mutableMapOf<String, Any>()

                            if (intent != null && intent.hasExtra("open_call_screen")) {
                                data["open_call_screen"] = true
                                data["caller_name"] =
                                        intent.getStringExtra("caller_name") ?: "Unknown"
                                data["caller_id"] = intent.getIntExtra("caller_id", 0)
                                data["is_video_call"] =
                                        intent.getBooleanExtra("is_video_call", false)

                                // Clear the intent so it doesn't trigger again
                                intent.removeExtra("open_call_screen")
                            }
                            result.success(data)
                        }
                        else -> result.notImplemented()
                    }
                }
    }

    private fun handleIncomingIntent() {
        handleIncomingIntent(intent)
    }

    private fun startCallForegroundService(
            callerName: String,
            isVideoCall: Boolean,
            targetUserId: String
    ) {
        val intent =
                Intent(this, CallForegroundService::class.java).apply {
                    action = CallForegroundService.ACTION_START_SERVICE
                    putExtra(CallForegroundService.EXTRA_CALLER_NAME, callerName)
                    putExtra(CallForegroundService.EXTRA_TARGET_USER_ID, targetUserId) // Add this
                    putExtra(CallForegroundService.EXTRA_IS_VIDEO_CALL, isVideoCall)
                }

        startService(intent)
    }

    private fun stopCallForegroundService() {
        val intent =
                Intent(this, CallForegroundService::class.java).apply {
                    action = CallForegroundService.ACTION_STOP_SERVICE
                }
        stopService(intent)
    }

    private fun toggleCallMute(isMuted: Boolean) {
        val intent =
                Intent(this, CallForegroundService::class.java).apply {
                    action = CallForegroundService.ACTION_TOGGLE_MUTE
                    putExtra(CallForegroundService.EXTRA_IS_MUTED, isMuted)
                }
        startService(intent)
    }

    private fun updateCallDuration(duration: String) {
        val intent =
                Intent(this, CallForegroundService::class.java).apply {
                    action = CallForegroundService.ACTION_UPDATE_DURATION
                    putExtra(CallForegroundService.EXTRA_DURATION, duration)
                }
        startService(intent)
    }

    private fun callConnected() {
        val intent =
                Intent(this, CallForegroundService::class.java).apply {
                    action = CallForegroundService.ACTION_CALL_CONNECTED
                }
        startService(intent)
    }

    private fun callDisconnected() {
        val intent =
                Intent(this, CallForegroundService::class.java).apply {
                    action = CallForegroundService.ACTION_CALL_DISCONNECTED
                }
        startService(intent)
    }

    private fun isCallServiceRunning(): Boolean {
        return CallForegroundService.isRunning
    }

    // Notification scheduling
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
                    if (timeInMillis <= System.currentTimeMillis())
                            add(java.util.Calendar.DAY_OF_YEAR, 1)
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

    private fun handleIncomingIntent(intent: Intent?) {
        log("🔍 handleIncomingIntent called: ${intent?.extras}")

        if (intent != null) {
            // Check for deep link data first
            val data = intent.data
            if (data != null && data.scheme == "picturo" && data.host == "call") {
                log("🔍 Deep link detected: $data")
                // Handle deep link if needed
            }

            // Check for notification intent
            if (intent.hasExtra("open_call_screen")) {
                val openCallScreen = intent.getBooleanExtra("open_call_screen", false)
                log("🔍 open_call_screen found: $openCallScreen")

                if (openCallScreen) {
                    val callerName = intent.getStringExtra("caller_name") ?: "Unknown"
                    val callerId = intent.getStringExtra("caller_id") ?: "0"
                    val isVideoCall = intent.getBooleanExtra("is_video_call", false)

                    log("🔍 Call data - Name: $callerName, ID: $callerId, Video: $isVideoCall")

                    // Send this data to Flutter
                    sendIntentToFlutter(callerName, callerId, isVideoCall)

                    // Clear the intent so it doesn't trigger again
                    intent.removeExtra("open_call_screen")
                }
            }
        }
    }

    private fun sendIntentToFlutter(callerName: String, callerId: String, isVideoCall: Boolean) {
        try {
            val data =
                    mapOf(
                            "open_call_screen" to true,
                            "caller_name" to callerName,
                            "caller_id" to callerId,
                            "is_video_call" to isVideoCall
                    )

            // You'll need to set up a method channel to send this to Flutter
            // For now, let's use a broadcast or store in shared preferences
            val prefs = getSharedPreferences("picturo_call_data", Context.MODE_PRIVATE)
            prefs.edit().apply {
                putBoolean("has_pending_call", true)
                putString("caller_name", callerName)
                putString("caller_id", callerId)
                putBoolean("is_video_call", isVideoCall)
                apply()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun cancelAllNotifications() {
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
