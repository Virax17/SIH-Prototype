import 'package:flutter_tts/flutter_tts.dart';

import '../models.dart';

const Map<LangCode, String> _locales = {
  LangCode.en: 'en-US',
  LangCode.hi: 'hi-IN',
  LangCode.ta: 'ta-IN',
};

/// Offline text-to-speech via the device's own OS TTS engine (no bundled
/// model — Android ships English out of the box; Hindi/Tamil speak correctly
/// once the user has that language's voice installed under
/// Settings > Text-to-speech, same as any other Android TTS app).
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  double _volume = 0.8;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await _tts.awaitSpeakCompletion(true);
    await _tts.setVolume(_volume);
    _initialized = true;
  }

  /// Sets playback volume (0.0-1.0), applied immediately if the engine is
  /// already initialized and to every `speak()` call after.
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_initialized) await _tts.setVolume(_volume);
  }

  /// Speaks [text] in [lang], invoking [onDone] when playback finishes (or
  /// fails) — the real completion signal that replaces the old fixed-Timer
  /// simulation.
  Future<void> speak(String text, LangCode lang, {void Function()? onDone}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      onDone?.call();
      return;
    }
    await _ensureInit();
    await _tts.setLanguage(_locales[lang] ?? 'en-US');
    await _tts.setVolume(_volume);
    _tts.setCompletionHandler(() => onDone?.call());
    _tts.setErrorHandler((_) => onDone?.call());
    await _tts.speak(trimmed);
  }

  Future<void> stop() => _tts.stop();
}
