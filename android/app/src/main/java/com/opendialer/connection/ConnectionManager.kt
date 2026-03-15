// android/app/src/main/java/com/opendialer/connection/OpenDialerConnectionService.kt
package com.opendialer.connection

import android.net.Uri
import android.os.Bundle
import android.telecom.Connection
import android.telecom.ConnectionRequest
import android.telecom.ConnectionService
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager

class OpenDialerConnectionService : ConnectionService() {

    override fun onCreateOutgoingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?
    ): Connection {
        val connection = OpenDialerConnection().apply {
            setAddress(request?.address, TelecomManager.PRESENTATION_ALLOWED)
            setCallerDisplayName(request?.address?.schemeSpecificPart, TelecomManager.PRESENTATION_ALLOWED)
            setDialing()
        }
        ConnectionManager.activeConnection = connection
        return connection
    }

    override fun onCreateIncomingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?
    ): Connection {
        val connection = OpenDialerConnection().apply {
            setAddress(request?.address, TelecomManager.PRESENTATION_ALLOWED)
            setCallerDisplayName(request?.address?.schemeSpecificPart, TelecomManager.PRESENTATION_ALLOWED)
            setRinging()
        }
        ConnectionManager.activeConnection = connection
        ConnectionManager.onIncomingCall(connection)
        return connection
    }

    override fun onCreateOutgoingConnectionFailed(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?
    ) {
        super.onCreateOutgoingConnectionFailed(connectionManagerPhoneAccount, request)
        ConnectionManager.onCallFailed()
    }
}

// ─── ConnectionManager (singleton bridge to Flutter) ─────────────────────────
// android/app/src/main/java/com/opendialer/connection/ConnectionManager.kt
package com.opendialer.connection

import android.telecom.CallAudioState

object ConnectionManager {
    var activeConnection: OpenDialerConnection? = null

    // Callbacks — set from MainActivity
    var onIncomingCallCallback: ((OpenDialerConnection) -> Unit)? = null
    var onCallAnsweredCallback: (() -> Unit)? = null
    var onCallRejectedCallback: (() -> Unit)? = null
    var onCallEndedCallback: (() -> Unit)? = null
    var onCallHeldCallback: (() -> Unit)? = null
    var onCallResumedCallback: (() -> Unit)? = null
    var onAudioStateChangedCallback: ((CallAudioState) -> Unit)? = null
    var onDtmfToneCallback: ((Char) -> Unit)? = null
    var onCallFailedCallback: (() -> Unit)? = null

    fun onIncomingCall(connection: OpenDialerConnection) {
        onIncomingCallCallback?.invoke(connection)
    }

    fun onCallAnswered() {
        onCallAnsweredCallback?.invoke()
    }

    fun onCallRejected() {
        onCallRejectedCallback?.invoke()
    }

    fun onCallEnded() {
        activeConnection = null
        onCallEndedCallback?.invoke()
    }

    fun onCallHeld() {
        onCallHeldCallback?.invoke()
    }

    fun onCallResumed() {
        onCallResumedCallback?.invoke()
    }

    fun onAudioStateChanged(state: CallAudioState) {
        onAudioStateChangedCallback?.invoke(state)
    }

    fun onDtmfTone(c: Char) {
        onDtmfToneCallback?.invoke(c)
    }

    fun onCallFailed() {
        onCallFailedCallback?.invoke()
    }

    // Actions called from Flutter via MethodChannel
    fun answerCall() = activeConnection?.onAnswer()
    fun rejectCall() = activeConnection?.onReject()
    fun hangUp() = activeConnection?.onDisconnect()
    fun holdCall() = activeConnection?.onHold()
    fun unholdCall() = activeConnection?.onUnhold()
    fun setMuted(muted: Boolean) = activeConnection?.setMuted(muted)
    fun setSpeaker(on: Boolean) = activeConnection?.setSpeakerphone(on)
}
