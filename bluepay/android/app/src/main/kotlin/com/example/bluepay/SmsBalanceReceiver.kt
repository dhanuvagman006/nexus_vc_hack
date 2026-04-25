package com.example.bluepay

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.SmsMessage
import android.util.Log

/**
 * Listens for incoming SMS messages from the relay phone.
 *
 * The relay app sends two types of balance-update SMS after processing a txn:
 *   BPAY S {txn_id} {amount} {newBalance}   ← sent to the SENDER
 *   BPAY R {txn_id} {amount} {newBalance}   ← sent to the RECEIVER
 *
 * Example: "BPAY S TXN174300012341234 500.00 850.00"
 *
 * When such an SMS is detected it is forwarded to Flutter via the
 * SmsEventStreamHandler EventChannel so the app can sync balances in real time.
 */
class SmsBalanceReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BPAYSmsReceiver"
        private const val RELAY_NUMBER = "6360139965"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action != "android.provider.Telephony.SMS_RECEIVED") return

        val extras = intent.extras ?: return
        val pdus   = extras.get("pdus") as? Array<*> ?: return
        val format = intent.getStringExtra("format") ?: "3gpp"

        for (pdu in pdus) {
            val sms  = SmsMessage.createFromPdu(pdu as ByteArray, format)
            val body = sms.messageBody?.trim() ?: continue
            val from = sms.originatingAddress ?: continue

            Log.d(TAG, "Incoming SMS from $from: $body")

            // Accept only BPAY messages (from any number — relay could vary)
            if (body.startsWith("BPAY ")) {
                Log.d(TAG, "BPAY balance-update SMS received: $body")
                SmsEventStreamHandler.emit(body)
            }
        }
    }
}
