import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

const _assetDir = 'assets/models/whisper-tiny';
const _modelFiles = ['tiny-encoder.int8.onnx', 'tiny-decoder.int8.onnx', 'tiny-tokens.txt'];
const _sampleRate = 16000;

/// Real, on-device speech-to-text using a Whisper-tiny (multilingual) model
/// via sherpa-onnx. Loads the model once at startup (copying it out of the
/// Flutter asset bundle to a real file, since the native recognizer needs a
/// filesystem path).
///
/// Whisper itself is non-streaming — there's no incremental decode API — so
/// "live" partial text is approximated by re-running the same recognizer on
/// the growing audio buffer every [_partialInterval] while the user holds
/// the button, rather than waiting for a genuinely different streaming
/// model. It's redundant compute (each pass re-reads from the start of the
/// utterance) but is simple, needs no extra model, and reads as "live" to
/// the user.
///
/// Only one recognizer instance is kept resident at a time — Whisper's
/// `language` hint is fixed at construction (sherpa-onnx does not yet support
/// a per-utterance override), so switching the app's spoken language rebuilds
/// the recognizer. [prepareLanguage] does this ahead of time (call it as soon
/// as the user picks a language, not lazily on PTT press) — rebuilding mid
/// recording would otherwise eat the start of the user's speech while the UI
/// already shows "Recording".
class SttService extends ChangeNotifier {
  static const _partialInterval = Duration(milliseconds: 1200);

  bool loading = true;
  bool ready = false;
  bool switchingLanguage = false;
  String? error;

  String partialText = '';

  String? _modelDir;
  sherpa_onnx.OfflineRecognizer? _recognizer;
  String _recognizerLanguage = '';
  Future<void>? _pendingBuild;

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioSub;
  Timer? _partialTimer;
  final BytesBuilder _pcmBuffer = BytesBuilder(copy: false);
  bool _partialBusy = false;

  Future<void> init({String initialLanguage = 'en'}) async {
    try {
      _modelDir = await _ensureModelFilesOnDisk();
      _buildRecognizer(initialLanguage);
      ready = true;
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String> _ensureModelFilesOnDisk() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/whisper-tiny');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    for (final name in _modelFiles) {
      final target = File('${dir.path}/$name');
      if (await target.exists()) continue;
      final bytes = await rootBundle.load('$_assetDir/$name');
      await target.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
    }
    return dir.path;
  }

  void _buildRecognizer(String language) {
    final dir = _modelDir;
    if (dir == null) return;
    try {
      final next = sherpa_onnx.OfflineRecognizer(
        sherpa_onnx.OfflineRecognizerConfig(
          model: sherpa_onnx.OfflineModelConfig(
            whisper: sherpa_onnx.OfflineWhisperModelConfig(
              encoder: '$dir/tiny-encoder.int8.onnx',
              decoder: '$dir/tiny-decoder.int8.onnx',
              language: language,
              task: 'transcribe',
            ),
            tokens: '$dir/tiny-tokens.txt',
            modelType: 'whisper',
            numThreads: 2,
            debug: false,
          ),
        ),
      );
      _recognizer?.free();
      _recognizer = next;
      _recognizerLanguage = language;
      error = null;
    } catch (e) {
      // Keep whatever recognizer was already loaded (e.g. English) rather
      // than leaving the service with none at all.
      error = 'Could not load speech model for "$language": $e';
    }
  }

  /// Rebuilds the recognizer for [language] ahead of time, if it isn't
  /// already the active one. Safe to call repeatedly (e.g. every time the
  /// language sheet closes) — a no-op once the right model is loaded.
  Future<void> prepareLanguage(String language) async {
    if (!ready || language == _recognizerLanguage) return;
    if (_pendingBuild != null) {
      await _pendingBuild;
      if (language == _recognizerLanguage) return;
    }
    switchingLanguage = true;
    notifyListeners();
    final completer = Completer<void>();
    _pendingBuild = completer.future;
    try {
      _buildRecognizer(language);
    } finally {
      switchingLanguage = false;
      _pendingBuild = null;
      completer.complete();
      notifyListeners();
    }
  }

  Future<bool> startRecording({required String language}) async {
    if (!ready) return false;
    try {
      if (!await _recorder.hasPermission()) return false;
      // Safety net: normally prepareLanguage() has already done this ahead
      // of time. If not (e.g. the user picked a language and pressed PTT
      // before the rebuild finished), finish it now rather than recording
      // against the wrong-language model.
      await prepareLanguage(language);
      if (_recognizer == null) return false;

      partialText = '';
      notifyListeners();

      final stream = await _recorder.startStream(
        const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: _sampleRate, numChannels: 1),
      );
      _audioSub = stream.listen((chunk) => _pcmBuffer.add(chunk));
      _partialTimer = Timer.periodic(_partialInterval, (_) => _runPartial());
      return true;
    } catch (e) {
      error = '$e';
      notifyListeners();
      return false;
    }
  }

  void _runPartial() {
    final recognizer = _recognizer;
    if (recognizer == null || _partialBusy || _pcmBuffer.length < _sampleRate ~/ 2) return;
    _partialBusy = true;
    try {
      final samples = _floatSamplesFrom(_pcmBuffer.toBytes());
      final stream = recognizer.createStream();
      stream.acceptWaveform(samples: samples, sampleRate: _sampleRate);
      recognizer.decode(stream);
      final text = recognizer.getResult(stream).text.trim();
      stream.free();
      if (text.isNotEmpty && text != partialText) {
        partialText = text;
        notifyListeners();
      }
    } catch (_) {
      // A partial pass failing isn't fatal — just skip this tick.
    } finally {
      _partialBusy = false;
    }
  }

  Float32List _floatSamplesFrom(Uint8List pcm16) {
    final byteData = ByteData.sublistView(pcm16);
    final n = pcm16.length ~/ 2;
    final out = Float32List(n);
    for (var i = 0; i < n; i++) {
      out[i] = byteData.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return out;
  }

  /// Stops recording and runs the recognizer on the captured audio.
  /// Returns the transcribed text, or null if nothing usable was captured.
  Future<String?> stopRecording() async {
    _partialTimer?.cancel();
    _partialTimer = null;
    await _audioSub?.cancel();
    _audioSub = null;
    await _recorder.stop();

    final recognizer = _recognizer;
    final bytes = _pcmBuffer.toBytes();
    _pcmBuffer.clear();
    partialText = '';
    notifyListeners();

    if (recognizer == null || bytes.length < _sampleRate ~/ 4) return null;

    try {
      final samples = _floatSamplesFrom(bytes);
      final stream = recognizer.createStream();
      stream.acceptWaveform(samples: samples, sampleRate: _sampleRate);
      recognizer.decode(stream);
      final result = recognizer.getResult(stream);
      stream.free();

      final text = result.text.trim();
      return text.isEmpty ? null : text;
    } catch (e) {
      error = '$e';
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _partialTimer?.cancel();
    _audioSub?.cancel();
    _recognizer?.free();
    _recorder.dispose();
    super.dispose();
  }
}
