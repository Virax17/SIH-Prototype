import 'dart:async';
import 'dart:convert';

import 'package:vosk_flutter/vosk_flutter.dart';

import '../models.dart';

const _sampleRate = 16000;

/// Offline speech-to-text using Vosk small models, one per [LangCode] that
/// has a bundled model (English and Hindi — Tamil has none, see README).
///
/// Vosk's [SpeechService] owns microphone capture itself on Android (no
/// separate recorder package needed): [startListening] starts it, and
/// [stopListening] stops it and returns the text of the utterance.
class SpeechRecognitionService {
  final _vosk = VoskFlutterPlugin.instance();
  final Map<LangCode, Model> _models = {};
  SpeechService? _speechService;
  StreamSubscription<String>? _resultSub;
  StreamSubscription<String>? _partialSub;
  String _lastText = '';

  /// Live partial transcript while listening — updates continuously as the
  /// user speaks, before the utterance is finalized. Empty string means "no
  /// partial yet" (e.g. right after starting, or on silence).
  final _partialController = StreamController<String>.broadcast();
  Stream<String> get onPartial => _partialController.stream;

  static const Map<LangCode, String> _assetZips = {
    // English: mid-tier "lgraph" model (~125MB) — meaningfully more accurate
    // than the small tier. Hindi has no equivalent middle ground (Vosk only
    // offers small-42MB or full-1.5GB for it), so it stays on small.
    LangCode.en: 'assets/models/vosk-model-en-us-0.22-lgraph.zip',
    LangCode.hi: 'assets/models/vosk-model-small-hi-0.22.zip',
  };

  bool supports(LangCode lang) => _assetZips.containsKey(lang);

  Future<Model> _modelFor(LangCode lang) async {
    final cached = _models[lang];
    if (cached != null) return cached;
    final assetPath = _assetZips[lang];
    if (assetPath == null) {
      throw StateError('No bundled Vosk model for $lang');
    }
    final path = await ModelLoader().loadFromAssets(assetPath);
    final model = await _vosk.createModel(path);
    _models[lang] = model;
    return model;
  }

  /// Loads the model for [lang] ahead of time, so the first real recording
  /// doesn't stall on a cold model load.
  Future<void> preload(LangCode lang) async {
    if (!supports(lang)) return;
    await _modelFor(lang);
  }

  /// Starts listening for speech in [lang]. Call [stopListening] to get the
  /// final recognized text.
  Future<void> startListening(LangCode lang) async {
    if (!supports(lang)) return;
    final model = await _modelFor(lang);
    final recognizer = await _vosk.createRecognizer(model: model, sampleRate: _sampleRate);
    _speechService = await _vosk.initSpeechService(recognizer);

    _lastText = '';
    await _resultSub?.cancel();
    await _partialSub?.cancel();
    _resultSub = _speechService!.onResult().listen((jsonStr) {
      final text = _extractField(jsonStr, 'text');
      if (text.isNotEmpty) _lastText = text;
    });
    _partialSub = _speechService!.onPartial().listen((jsonStr) {
      _partialController.add(_extractField(jsonStr, 'partial'));
    });

    await _speechService!.start();
  }

  /// Stops listening and returns the recognized text (empty if nothing was
  /// understood, or if [lang] has no bundled model).
  Future<String> stopListening() async {
    final service = _speechService;
    if (service == null) return '';

    await service.stop();

    // Wait for the final result event (emitted asynchronously after stop())
    // to reach `_resultSub`. A fixed short delay was unreliable — on a
    // slower device or a longer phrase, the final-result computation can
    // take longer than that, silently dropping the whole utterance. Poll
    // briefly instead, returning as soon as text actually arrives rather
    // than always waiting (or not waiting long enough).
    for (var i = 0; i < 15 && _lastText.isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    await _resultSub?.cancel();
    await _partialSub?.cancel();
    await service.dispose();
    _speechService = null;
    _partialController.add('');

    final text = _lastText;
    _lastText = '';
    return text;
  }

  String _extractField(String resultJson, String field) {
    try {
      final decoded = jsonDecode(resultJson) as Map<String, dynamic>;
      return (decoded[field] as String?)?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }
}
