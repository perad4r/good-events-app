package com.sukientot.app

import android.media.AudioManager
import android.media.Ringtone
import android.media.RingtoneManager
import android.media.ToneGenerator
import android.os.Build
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.sukientot.app/call_audio"
    private var ringtone: Ringtone? = null
    private var toneGenerator: ToneGenerator? = null
    private var callAudioMethodChannel: MethodChannel? = null
    private var pendingCallAction: Map<String, Any?>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        captureCallAction(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        captureCallAction(intent)
        pendingCallAction?.let {
            callAudioMethodChannel?.invokeMethod("nativeCallAction", it)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        callAudioMethodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "playIncoming" -> {
                        playIncomingRingtone()
                        result.success(null)
                    }
                    "playOutgoing" -> {
                        playOutgoingTone()
                        result.success(null)
                    }
                    "stop" -> {
                        stopCallAudio()
                        result.success(null)
                    }
                    "startOngoingCall" -> {
                        val callId = call.argument<String>("call_id").orEmpty()
                        CallAudioForegroundService.start(applicationContext, callId)
                        result.success(null)
                    }
                    "stopOngoingCall" -> {
                        stopService(Intent(applicationContext, CallAudioForegroundService::class.java))
                        result.success(null)
                    }
                    "consumePendingCallAction" -> {
                        result.success(pendingCallAction)
                        pendingCallAction = null
                    }
                    "clearPendingCallAction" -> {
                        pendingCallAction = null
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun playIncomingRingtone() {
        stopCallAudio()
        val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
        ringtone = RingtoneManager.getRingtone(applicationContext, uri)?.apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) isLooping = true
            play()
        }
    }

    private fun playOutgoingTone() {
        stopCallAudio()
        toneGenerator = ToneGenerator(AudioManager.STREAM_VOICE_CALL, 70).apply {
            startTone(ToneGenerator.TONE_SUP_RINGTONE)
        }
    }

    private fun stopCallAudio() {
        ringtone?.stop()
        ringtone = null
        toneGenerator?.stopTone()
        toneGenerator?.release()
        toneGenerator = null
    }

    @Suppress("DEPRECATION", "UNCHECKED_CAST")
    private fun captureCallAction(intent: Intent?) {
        val action = intent?.action ?: return
        val normalizedAction = when {
            action.endsWith("ACTION_CALL_ACCEPT") -> "accept"
            action.endsWith("ACTION_CALL_DECLINE") -> "decline"
            action.endsWith("ACTION_CALL_ENDED") -> "end"
            else -> return
        }
        val callBundle = intent.getBundleExtra("EXTRA_CALLKIT_CALL_DATA") ?: return
        val extra = callBundle.getSerializable("EXTRA_CALLKIT_EXTRA") as? Map<String, Any?>
            ?: return
        pendingCallAction = mapOf(
            "action" to normalizedAction,
            "data" to extra,
        )
    }

    override fun onDestroy() {
        stopCallAudio()
        super.onDestroy()
    }
}
