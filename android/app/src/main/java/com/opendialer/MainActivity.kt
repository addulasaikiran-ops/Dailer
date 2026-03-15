// android/app/src/main/java/com/opendialer/MainActivity.kt
package com.opendialer

import android.app.role.RoleManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.telecom.PhoneAccount
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import androidx.annotation.NonNull
import com.opendialer.connection.ConnectionManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val TELECOM_CHANNEL = "com.opendialer/telecom"
        private const val CALL_EVENTS_CHANNEL = "com.opendialer/call_events"
        private const val REQUEST_DEFAULT_DIALER_CODE = 1001
    }

    private lateinit var telecomManager: TelecomManager
    private var callEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        telecomManager = getSystemService(TELECOM_SERVICE) as TelecomManager

        // ── Register phone account ──────────────────────────────
        registerPhoneAccount()

        // ── MethodChannel (Flutter → Native) ──────────────────
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            TELECOM_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestDefaultDialer" -> requestDefaultDialer(result)
                "isDefaultDialer" -> result.success(isDefaultDialer())
                "makeCall" -> {
                    val number = call.argument<String>("number") ?: ""
                    val sim = call.argument<Int>("simSlot") ?: 0
                    makeCall(number, sim, result)
                }
                "answerCall" -> {
                    ConnectionManager.answerCall()
                    result.success(null)
                }
                "rejectCall" -> {
                    ConnectionManager.rejectCall()
                    result.success(null)
                }
                "hangUp" -> {
                    ConnectionManager.hangUp()
                    result.success(null)
                }
                "holdCall" -> {
                    ConnectionManager.holdCall()
                    result.success(null)
                }
                "unholdCall" -> {
                    ConnectionManager.unholdCall()
                    result.success(null)
                }
                "setMuted" -> {
                    val muted = call.argument<Boolean>("muted") ?: false
                    ConnectionManager.setMuted(muted)
                    result.success(null)
                }
                "setSpeaker" -> {
                    val on = call.argument<Boolean>("on") ?: false
                    ConnectionManager.setSpeaker(on)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // ── EventChannel (Native → Flutter) ───────────────────
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CALL_EVENTS_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                callEventSink = events
                setupConnectionManagerCallbacks()
            }

            override fun onCancel(arguments: Any?) {
                callEventSink = null
            }
        })
    }

    private fun setupConnectionManagerCallbacks() {
        ConnectionManager.onIncomingCallCallback = { _ ->
            runOnUiThread {
                callEventSink?.success(mapOf("event" to "incoming"))
                // Navigate Flutter to incoming call screen
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, TELECOM_CHANNEL)
                        .invokeMethod("navigateToIncoming", null)
                }
            }
        }
        ConnectionManager.onCallAnsweredCallback = {
            runOnUiThread {
                callEventSink?.success(mapOf("event" to "answered"))
            }
        }
        ConnectionManager.onCallRejectedCallback = {
            runOnUiThread {
                callEventSink?.success(mapOf("event" to "rejected"))
            }
        }
        ConnectionManager.onCallEndedCallback = {
            runOnUiThread {
                callEventSink?.success(mapOf("event" to "ended"))
            }
        }
        ConnectionManager.onAudioStateChangedCallback = { state ->
            runOnUiThread {
                callEventSink?.success(mapOf(
                    "event" to "audioState",
                    "isMuted" to state.isMuted,
                    "isSpeaker" to (state.route == android.telecom.CallAudioState.ROUTE_SPEAKER)
                ))
            }
        }
    }

    private fun registerPhoneAccount() {
        val handle = PhoneAccountHandle(
            android.content.ComponentName(this, com.opendialer.connection.OpenDialerConnectionService::class.java),
            "OpenDialer"
        )
        val account = PhoneAccount.builder(handle, "OpenDialer")
            .setCapabilities(PhoneAccount.CAPABILITY_CALL_PROVIDER or PhoneAccount.CAPABILITY_SIM_SUBSCRIPTION)
            .build()
        telecomManager.registerPhoneAccount(account)
    }

    private fun isDefaultDialer(): Boolean {
        return packageName == telecomManager.defaultDialerPackage
    }

    private fun requestDefaultDialer(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(RoleManager::class.java)
            if (roleManager.isRoleAvailable(RoleManager.ROLE_DIALER) &&
                !roleManager.isRoleHeld(RoleManager.ROLE_DIALER)
            ) {
                val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_DIALER)
                startActivityForResult(intent, REQUEST_DEFAULT_DIALER_CODE)
                result.success(null)
            } else {
                result.success(null)
            }
        } else {
            val intent = Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER)
                .putExtra(TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, packageName)
            startActivityForResult(intent, REQUEST_DEFAULT_DIALER_CODE)
            result.success(null)
        }
    }

    private fun makeCall(number: String, simSlot: Int, result: MethodChannel.Result) {
        try {
            val uri = Uri.fromParts("tel", number, null)
            val extras = Bundle().apply {
                putInt(TelecomManager.EXTRA_START_CALL_WITH_VIDEO_STATE, 0)
            }
            telecomManager.placeCall(uri, extras)
            result.success(null)
        } catch (e: SecurityException) {
            result.error("PERMISSION_DENIED", "CALL_PHONE permission required", null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_DEFAULT_DIALER_CODE) {
            // Result handled; Flutter will re-check via isDefaultDialer
        }
    }
}
