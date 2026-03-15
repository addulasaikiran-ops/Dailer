// android/app/src/main/java/com/opendialer/service/OpenInCallService.kt
package com.opendialer.service

import android.telecom.Call
import android.telecom.InCallService
import android.telecom.VideoProfile
import com.opendialer.connection.ConnectionManager

/**
 * OpenInCallService
 *
 * Bridges the Android Telecom framework with the Flutter UI.
 * When Android routes a call through its telephony stack (vs our own
 * ConnectionService), this InCallService receives the call object and
 * notifies the Flutter layer so it can show the in-call UI.
 */
class OpenInCallService : InCallService() {

    private val callCallback = object : Call.Callback() {
        override fun onStateChanged(call: Call, state: Int) {
            handleStateChange(call, state)
        }
    }

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        call.registerCallback(callCallback)
        handleStateChange(call, call.state)
    }

    override fun onCallRemoved(call: Call) {
        super.onCallRemoved(call)
        call.unregisterCallback(callCallback)
        ConnectionManager.onCallEnded()
    }

    private fun handleStateChange(call: Call, state: Int) {
        when (state) {
            Call.STATE_RINGING -> {
                // Show incoming call UI via Flutter
                ConnectionManager.onIncomingCall(com.opendialer.connection.OpenDialerConnection())
            }
            Call.STATE_ACTIVE -> ConnectionManager.onCallAnswered()
            Call.STATE_DISCONNECTED -> ConnectionManager.onCallEnded()
            Call.STATE_HOLDING -> ConnectionManager.onCallHeld()
        }
    }
}
