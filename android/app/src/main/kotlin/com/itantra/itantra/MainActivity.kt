package com.itantra.itantra

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Lets the volume-up + volume-down combo act as a hardware push-to-talk
 * button. While this activity is in the foreground, volume key events are
 * intercepted here and never reach the system volume handler — holding
 * either key alone does nothing (by design: the buttons are dedicated to
 * PTT while the app is open), and holding both starts/stops recording.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "itantra/volume_ptt"
    private var methodChannel: MethodChannel? = null
    private var volUpPressed = false
    private var volDownPressed = false
    private var comboActive = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val isVolumeKey = event.keyCode == KeyEvent.KEYCODE_VOLUME_UP || event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN
        if (!isVolumeKey) return super.dispatchKeyEvent(event)

        when (event.action) {
            KeyEvent.ACTION_DOWN -> {
                if (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP) volUpPressed = true
                if (event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) volDownPressed = true
                if (volUpPressed && volDownPressed && !comboActive) {
                    comboActive = true
                    methodChannel?.invokeMethod("comboPressed", null)
                }
            }
            KeyEvent.ACTION_UP -> {
                if (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP) volUpPressed = false
                if (event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) volDownPressed = false
                if (comboActive && !(volUpPressed && volDownPressed)) {
                    comboActive = false
                    methodChannel?.invokeMethod("comboReleased", null)
                }
            }
        }
        return true
    }
}
