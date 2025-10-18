package com.picturo.picturoenglish

import android.content.Context
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class SystemCallDetectorPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var context: Context? = null
    private var eventSink: EventChannel.EventSink? = null
    private var telephonyManager: TelephonyManager? = null
    private var phoneStateListener: PhoneStateListener? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext

        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "system_call_detector")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "system_call_events")
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        context = null
        cleanup()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initializeSystemCallDetection" -> {
                initializePhoneStateListener()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun initializePhoneStateListener() {
        context?.let { ctx ->
            telephonyManager = ctx.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
            phoneStateListener =
                    object : PhoneStateListener() {
                        override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                            when (state) {
                                TelephonyManager.CALL_STATE_RINGING -> eventSink?.success("RINGING")
                                TelephonyManager.CALL_STATE_OFFHOOK -> eventSink?.success("OFFHOOK")
                                TelephonyManager.CALL_STATE_IDLE -> eventSink?.success("IDLE")
                            }
                        }
                    }

            telephonyManager?.listen(phoneStateListener, PhoneStateListener.LISTEN_CALL_STATE)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
        cleanup()
    }

    private fun cleanup() {
        phoneStateListener?.let { listener ->
            telephonyManager?.listen(listener, PhoneStateListener.LISTEN_NONE)
        }
        phoneStateListener = null
        telephonyManager = null
    }
}
