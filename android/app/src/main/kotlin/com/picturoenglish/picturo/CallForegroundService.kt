package com.picturo.picturoenglish

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.*

class CallForegroundService : Service() {
    private val serviceScope = CoroutineScope(Dispatchers.Main)
    private var callStartTime: Long = 0
    private var isMuted = false
    private var callerName = "Unknown"
    private var targetUserId = "0" // Initialize with default value
    private var isVideoCall = false
    private var callDuration = "00:00"
    private var isCallActive = false
    private var durationUpdateJob: Job? = null

    companion object {
        var isRunning = false
        var isCallConnected = false

        const val NOTIFICATION_ID = 888
        const val CHANNEL_ID = "picturo_call_channel"
        const val ACTION_START_SERVICE = "ACTION_START_SERVICE"
        const val ACTION_STOP_SERVICE = "ACTION_STOP_SERVICE"
        const val ACTION_TOGGLE_MUTE = "ACTION_TOGGLE_MUTE"
        const val ACTION_UPDATE_DURATION = "ACTION_UPDATE_DURATION"
        const val ACTION_CALL_CONNECTED = "ACTION_CALL_CONNECTED"
        const val ACTION_CALL_DISCONNECTED = "ACTION_CALL_DISCONNECTED"

        const val EXTRA_CALLER_NAME = "EXTRA_CALLER_NAME"
        const val EXTRA_TARGET_USER_ID = "EXTRA_TARGET_USER_ID" // Add this
        const val EXTRA_IS_MUTED = "EXTRA_IS_MUTED"
        const val EXTRA_DURATION = "EXTRA_DURATION"
        const val EXTRA_IS_VIDEO_CALL = "EXTRA_IS_VIDEO_CALL"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_SERVICE -> {
                // Store call info but don't start foreground service yet
                callerName = intent.getStringExtra(EXTRA_CALLER_NAME) ?: "Unknown"
                targetUserId =
                        intent.getStringExtra(EXTRA_TARGET_USER_ID) ?: "0" // Get target user ID
                isVideoCall = intent.getBooleanExtra(EXTRA_IS_VIDEO_CALL, false)
                isRunning = true
                isCallActive = false
                isCallConnected = false

                // Only create a low-priority notification, not foreground service
                showWaitingNotification()
            }
            ACTION_CALL_CONNECTED -> {
                // Call is actually connected - start foreground service now
                callStartTime = System.currentTimeMillis()
                isCallActive = true
                isCallConnected = true
                startForegroundService()
                startDurationUpdates()
                updateCallNotification()
            }
            ACTION_CALL_DISCONNECTED -> {
                isCallActive = false
                isCallConnected = false
                stopDurationUpdates()
                stopForegroundService()
            }
            ACTION_STOP_SERVICE -> {
                stopForegroundService()
            }
            ACTION_TOGGLE_MUTE -> {
                isMuted = intent.getBooleanExtra(EXTRA_IS_MUTED, false)
                if (isCallConnected) {
                    updateCallNotification()
                }
            }
            ACTION_UPDATE_DURATION -> {
                callDuration = intent.getStringExtra(EXTRA_DURATION) ?: "00:00"
                if (isCallConnected) {
                    updateCallNotification()
                }
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        isCallConnected = false
        isCallActive = false
        stopDurationUpdates()
        serviceScope.cancel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel =
                    NotificationChannel(
                                    CHANNEL_ID,
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
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun startForegroundService() {
        val notification = buildCallNotification()
        startForeground(NOTIFICATION_ID, notification)
    }

    private fun showWaitingNotification() {
        // Create a simple notification that doesn't keep the service in foreground
        val notification = buildWaitingNotification()
        val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    private fun startDurationUpdates() {
        stopDurationUpdates()
        durationUpdateJob =
                serviceScope.launch {
                    while (isCallActive && isRunning) {
                        delay(1000)
                        updateCallDuration()
                    }
                }
    }

    private fun stopDurationUpdates() {
        durationUpdateJob?.cancel()
        durationUpdateJob = null
    }

    private fun stopForegroundService() {
        isRunning = false
        isCallActive = false
        isCallConnected = false
        stopDurationUpdates()
        serviceScope.cancel()
        stopForeground(true)
        stopSelf()

        // Remove the notification
        val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(NOTIFICATION_ID)
    }

    private fun updateCallDuration() {
        if (isCallActive) {
            val duration = System.currentTimeMillis() - callStartTime
            callDuration = formatDuration(duration)
            updateCallNotification()
        }
    }

    private fun updateCallNotification() {
        if (isCallConnected) {
            val notification = buildCallNotification()
            val notificationManager =
                    getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID, notification)
        }
    }

    private fun buildWaitingNotification(): Notification {
        val callType = if (isVideoCall) "Video Call" else "Voice Call"

        val intent =
                Intent(this, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
        val pendingIntent =
                PendingIntent.getActivity(
                        this,
                        0,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

        return NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Picturo - Connecting $callType...")
                .setContentText("Calling $callerName")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentIntent(pendingIntent)
                .setOngoing(false) // Not ongoing - can be dismissed
                .setOnlyAlertOnce(true)
                .setSilent(true)
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setCategory(NotificationCompat.CATEGORY_CALL)
                .build()
    }

    private fun buildCallNotification(): Notification {
        val muteText = if (isMuted) " (Muted)" else ""
        val callType = if (isVideoCall) "Video Call" else "Voice Call"

        val intent =
                Intent(this, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("open_call_screen", true)
                    putExtra("caller_name", callerName)
                    putExtra("caller_id", targetUserId) // Now targetUserId is available
                    putExtra("is_video_call", isVideoCall)
                }
        val pendingIntent =
                PendingIntent.getActivity(
                        this,
                        0,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

        return NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Picturo - $callType with $callerName")
                .setContentText("Duration: $callDuration$muteText")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentIntent(pendingIntent)
                .setOngoing(true) // Ongoing - cannot be dismissed
                .setOnlyAlertOnce(true)
                .setSilent(true)
                .setAutoCancel(false)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setCategory(NotificationCompat.CATEGORY_CALL)
                .build()
    }

    private fun formatDuration(millis: Long): String {
        val hours = TimeUnit.MILLISECONDS.toHours(millis)
        val minutes = TimeUnit.MILLISECONDS.toMinutes(millis) % 60
        val seconds = TimeUnit.MILLISECONDS.toSeconds(millis) % 60

        return String.format("%02d:%02d:%02d", hours, minutes, seconds)
    }
}
