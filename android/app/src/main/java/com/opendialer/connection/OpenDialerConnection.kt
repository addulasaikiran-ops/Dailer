// android/app/src/main/java/com/opendialer/connection/OpenDialerConnection.kt
package com.opendialer.connection

import android.net.Uri
import android.os.Bundle
import android.telecom.CallAudioState
import android.telecom.Connection
import android.telecom.DisconnectCause

class OpenDialerConnection : Connection() {

    init {
        audioModeIsVoip = true
        connectionCapabilities = (
            CAPABILITY_HOLD or
            CAPABILITY_SUPPORT_HOLD or
            CAPABILITY_MUTE or
            CAPABILITY_MANAGE_CONFERENCE
        )
    }

    override fun onShowIncomingCallUi() {
        super.onShowIncomingCallUi()
        // Flutter activity handles incoming call display
    }

    override fun onAnswer() {
        setActive()
        ConnectionManager.onCallAnswered()
    }

    override fun onReject() {
        setDisconnected(DisconnectCause(DisconnectCause.REJECTED))
        destroy()
        ConnectionManager.onCallRejected()
    }

    override fun onHold() {
        setOnHold()
        ConnectionManager.onCallHeld()
    }

    override fun onUnhold() {
        setActive()
        ConnectionManager.onCallResumed()
    }

    override fun onDisconnect() {
        setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
        destroy()
        ConnectionManager.onCallEnded()
    }

    override fun onCallAudioStateChanged(state: CallAudioState?) {
        super.onCallAudioStateChanged(state)
        state?.let {
            ConnectionManager.onAudioStateChanged(it)
        }
    }

    override fun onPlayDtmfTone(c: Char) {
        ConnectionManager.onDtmfTone(c)
    }

    override fun onStopDtmfTone() {}

    fun setMuted(muted: Boolean) {
        val newRoute = callAudioState?.route ?: CallAudioState.ROUTE_EARPIECE
        setAudioRoute(newRoute)
    }

    fun setSpeakerphone(on: Boolean) {
        setAudioRoute(if (on) CallAudioState.ROUTE_SPEAKER else CallAudioState.ROUTE_EARPIECE)
    }
}
