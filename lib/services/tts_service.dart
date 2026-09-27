import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

const _assetDir = 'assets/models/tts';

/// Piper-family voices (English, Hindi) need espeak-ng to turn raw text into
/// phonemes before synthesis. The Tamil voice (a community conversion of
/// Meta's MMS-TTS) is a plain character-level model — its tokens.txt already
/// maps Tamil script directly, no phonemizer involved — so it must NOT be
/// given the espeak data dir, or sherpa-onnx would try to phonemize Tamil
/// text meant for a model that never expected phonemes.
const _piperLanguages = {'en', 'hi'};

/// Real, on-device text-to-speech using per-language VITS models via
/// sherpa-onnx: Piper voices for English/Hindi, a community MMS-TTS
/// conversion for Tamil (no official lightweight Tamil voice exists yet for
/// sherpa-onnx). Only one voice is kept resident in memory at a time,
/// matching the same lazy-swap approach used for [SttService].
class TtsService extends ChangeNotifier {
  bool loading = true;
  bool ready = false;
  bool switchingVoice = false;
  bool speaking = false;
  String? error;

  String? _filesDir;
  sherpa_onnx.OfflineTts? _tts;
  String _ttsLanguage = '';
  Future<void>? _pendingBuild;

  final AudioPlayer _player = AudioPlayer();
  int _playToken = 0;

  Future<void> init({String initialLanguage = 'en'}) async {
    try {
      _filesDir = await _ensureSharedFilesOnDisk();
      await _buildTts(initialLanguage);
      ready = true;
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String> _ensureSharedFilesOnDisk() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/tts');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final espeakDir = Directory('${dir.path}/espeak-ng-data');
    if (!await espeakDir.exists()) {
      final zipBytes = await rootBundle.load('$_assetDir/espeak-ng-data.zip');
      final archive = ZipDecoder().decodeBytes(zipBytes.buffer.asUint8List(zipBytes.offsetInBytes, zipBytes.lengthInBytes));
      for (final entry in archive) {
        if (!entry.isFile) continue;
        final outFile = File('${dir.path}/${entry.name}');
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(entry.content as List<int>);
      }
    }
    return dir.path;
  }

  Future<void> _ensureLanguageFiles(String language) async {
    final dir = Directory('$_filesDir/$language');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    for (final name in ['model.onnx', 'tokens.txt']) {
      final target = File('${dir.path}/$name');
      if (await target.exists()) continue;
      final bytes = await rootBundle.load('$_assetDir/$language/$name');
      await target.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
    }
  }

  Future<void> _buildTts(String language) async {
    try {
      await _ensureLanguageFiles(language);
      final langDir = '$_filesDir/$language';
      final usesPiper = _piperLanguages.contains(language);
      final next = sherpa_onnx.OfflineTts(
        sherpa_onnx.OfflineTtsConfig(
          model: sherpa_onnx.OfflineTtsModelConfig(
            vits: sherpa_onnx.OfflineTtsVitsModelConfig(
              model: '$langDir/model.onnx',
              tokens: '$langDir/tokens.txt',
              dataDir: usesPiper ? '$_filesDir/espeak-ng-data' : '',
            ),
            numThreads: 2,
            debug: false,
          ),
        ),
      );
      _tts?.free();
      _tts = next;
      _ttsLanguage = language;
      error = null;
    } catch (e) {
      error = 'Could not load voice for "$language": $e';
    }
  }

  /// Rebuilds the voice for [language] ahead of time, if it isn't already
  /// the active one. Safe to call repeatedly.
  Future<void> prepareLanguage(String language) async {
    if (!ready || language == _ttsLanguage) return;
    if (_pendingBuild != null) {
      await _pendingBuild;
      if (language == _ttsLanguage) return;
    }
    switchingVoice = true;
    notifyListeners();
    final completer = Completer<void>();
    _pendingBuild = completer.future;
    try {
      await _buildTts(language);
    } finally {
      switchingVoice = false;
      _pendingBuild = null;
      completer.complete();
      notifyListeners();
    }
  }

  /// Synthesizes [text] in [language] and plays it aloud. Cancels/replaces
  /// any speech already in progress. Returns once playback has finished (or
  /// failed) — callers use this to know when to clear a "playing" indicator.
  Future<void> speak({required String text, required String language}) async {
    if (!ready || text.trim().isEmpty) return;
    final myToken = ++_playToken;
    speaking = true;
    notifyListeners();

    try {
      await prepareLanguage(language);
      final tts = _tts;
      if (tts == null || myToken != _playToken) return;

      final audio = tts.generate(text: text, sid: 0, speed: 1.0);
      if (myToken != _playToken) return;

      final tmp = await getTemporaryDirectory();
      final outPath = '${tmp.path}/itantra_tts_out.wav';
      sherpa_onnx.writeWave(filename: outPath, samples: audio.samples, sampleRate: audio.sampleRate);
      if (myToken != _playToken) return;

      final completer = Completer<void>();
      late final StreamSubscription sub;
      sub = _player.onPlayerComplete.listen((_) {
        sub.cancel();
        if (!completer.isCompleted) completer.complete();
      });
      await _player.play(DeviceFileSource(outPath));
      await completer.future.timeout(const Duration(seconds: 30), onTimeout: () {});
    } catch (e) {
      error = '$e';
    } finally {
      if (myToken == _playToken) {
        speaking = false;
        notifyListeners();
      }
    }
  }

  Future<void> stop() async {
    _playToken++;
    speaking = false;
    await _player.stop();
    notifyListeners();
  }

  @override
  void dispose() {
    _tts?.free();
    _player.dispose();
    super.dispose();
  }
}
