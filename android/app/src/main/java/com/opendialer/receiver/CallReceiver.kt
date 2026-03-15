// android/app/src/main/java/com/opendialer/receiver/CallReceiver.kt
package com.opendialer.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.util.Log

/**
 * CallReceiver
 *
 * Listens for incoming call broadcasts and new outgoing call intents.
 * Used as a secondary signal source alongside the ConnectionService /
 * InCallService to ensure call events are captured reliably on all OEM
 * Android variants.
 */
class CallReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "OpenDialer:CallReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_NEW_OUTGOING_CALL -> {
                val number = intent.getStringExtra(Intent.EXTRA_PHONE_NUMBER)
                Log.d(TAG, "New outgoing call: $number")
                // Can be used to block/transform the outgoing number
            }
            TelephonyManager.ACTION_PHONE_STATE_CHANGED -> {
                val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
                val number = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
                Log.d(TAG, "Phone state: $state, number: $number")
                when (state) {
                    TelephonyManager.EXTRA_STATE_RINGING -> {
                        Log.d(TAG, "Incoming call ringing: $number")
                    }
                    TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                        Log.d(TAG, "Call picked up")
                    }
                    TelephonyManager.EXTRA_STATE_IDLE -> {
                        Log.d(TAG, "Call ended / idle")
                    }
                }
            }
        }
    }
}
