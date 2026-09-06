import 'package:flutter/services.dart';

/// Bridges the volume-up + volume-down hardware combo (intercepted natively
/// in MainActivity.kt) to push-to-talk start/stop callbacks.
class VolumePttService {
  static const _channel = MethodChannel('itantra/volume_ptt');

  static void init({required void Function() onComboPressed, required void Function() onComboReleased}) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'comboPressed':
          onComboPressed();
        case 'comboReleased':
          onComboReleased();
      }
    });
  }
}
