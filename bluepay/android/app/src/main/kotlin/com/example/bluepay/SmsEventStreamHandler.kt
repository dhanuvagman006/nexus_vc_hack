package com.example.bluepay

import io.flutter.plugin.common.EventChannel

/**
 * Singleton EventChannel stream handler.
 *
 * The SmsBalanceReceiver (BroadcastReceiver) calls emit() whenever a BPAY SMS
 * arrives. The Flutter SmsBalanceService listens on the EventChannel and
 * updates AppState with the new balance.
 */
object SmsEventStreamHandler : EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    /** Called from SmsBalanceReceiver to push a message to Flutter. */
    fun emit(message: String) {
        // Must be called on the main thread; EventSink is not thread-safe.
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            eventSink?.success(message)
        }
    }
}
