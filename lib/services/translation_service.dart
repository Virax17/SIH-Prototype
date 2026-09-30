import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_sentencepiece_tokenizer/dart_sentencepiece_tokenizer.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:onnxruntime/onnxruntime.dart';

import '../models.dart';

/// One loaded encoder+decoder translation direction (e.g. en→hi), plus the
/// pieces needed to tokenize into it and detokenize out of it.
///
/// Marian/OPUS-MT tokenization is: SentencePiece-segment the text into piece
/// *strings* with the direction's `.spm` model, then look up each piece's id
/// in the direction's shared `vocab.json` — the id space that trained the
/// exported ONNX graphs, which does not necessarily match the `.spm` file's
/// own internal piece-id ordering. Decoding runs the same lookup in reverse.
class _Direction {
  final OrtSession encoder;
  final OrtSession decoder;
  final SentencePieceTokenizer sourceSpm;
  final SentencePieceTokenizer targetSpm;
  final Map<String, int> vocab;
  final Map<int, String> idToToken;
  final int decoderStartTokenId;
  final int eosTokenId;

  _Direction({
    required this.encoder,
    required this.decoder,
    required this.sourceSpm,
    required this.targetSpm,
    required this.vocab,
    required this.idToToken,
    required this.decoderStartTokenId,
    required this.eosTokenId,
  });
}

/// Offline English↔Hindi machine translation using quantized ONNX exports of
/// Helsinki-NLP's OPUS-MT (Marian) models — one direction loaded lazily per
/// (from, to) pair the app actually uses, from `assets/models/mt-{from}-{to}/`.
class TranslationService {
  final Map<String, _Direction> _directions = {};
  bool _envInitialized = false;

  void _ensureEnv() {
    if (_envInitialized) return;
    OrtEnv.instance.init();
    _envInitialized = true;
  }

  String _key(LangCode from, LangCode to) => '${from.name}-${to.name}';

  bool _supported(LangCode from, LangCode to) =>
      (from == LangCode.en && to == LangCode.hi) || (from == LangCode.hi && to == LangCode.en);

  /// Loads the ONNX sessions and tokenizers for a `from`-to-`to` direction,
  /// if not already loaded. Safe to call ahead of time to avoid a
  /// first-translate stall.
  Future<void> preload(LangCode from, LangCode to) async {
    if (from == to || !_supported(from, to)) return;
    final key = _key(from, to);
    if (_directions.containsKey(key)) return;
    _ensureEnv();

    final dir = 'assets/models/mt-${from.name}-${to.name}';

    final encoderBytes = await _loadAsset('$dir/encoder_model_quantized.onnx');
    final decoderBytes = await _loadAsset('$dir/decoder_model_quantized.onnx');
    final sourceSpmBytes = await _loadAsset('$dir/source.spm');
    final targetSpmBytes = await _loadAsset('$dir/target.spm');
    final vocabJson = await rootBundle.loadString('$dir/vocab.json');
    final genConfigJson = await rootBundle.loadString('$dir/generation_config.json');

    final sessionOptions = OrtSessionOptions();
    final encoder = OrtSession.fromBuffer(encoderBytes, sessionOptions);
    final decoder = OrtSession.fromBuffer(decoderBytes, sessionOptions);

    final sourceSpm = SentencePieceTokenizer.fromBytes(sourceSpmBytes);
    final targetSpm = SentencePieceTokenizer.fromBytes(targetSpmBytes);

    final vocab = (jsonDecode(vocabJson) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int));
    final idToToken = {for (final e in vocab.entries) e.value: e.key};

    final genConfig = jsonDecode(genConfigJson) as Map<String, dynamic>;

    _directions[key] = _Direction(
      encoder: encoder,
      decoder: decoder,
      sourceSpm: sourceSpm,
      targetSpm: targetSpm,
      vocab: vocab,
      idToToken: idToToken,
      decoderStartTokenId: genConfig['decoder_start_token_id'] as int,
      eosTokenId: genConfig['eos_token_id'] as int,
    );
  }

  Future<Uint8List> _loadAsset(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  /// Translates [text] from [from] to [to]. Returns [text] unchanged if the
  /// pair is identity or not one of the bundled directions (e.g. Tamil).
  Future<String> translate(String text, {required LangCode from, required LangCode to}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || from == to || !_supported(from, to)) return trimmed;

    await preload(from, to);
    final dir = _directions[_key(from, to)];
    if (dir == null) return trimmed;

    // --- Encode: text -> SentencePiece pieces -> vocab.json ids -> </s> ---
    final pieces = dir.sourceSpm.tokenize(trimmed);
    final unkId = dir.vocab['<unk>'] ?? 0;
    final inputIds = [
      ...pieces.map((p) => dir.vocab[p] ?? unkId),
      dir.eosTokenId,
    ];

    final runOptions = OrtRunOptions();

    final inputIdsTensor = OrtValueTensor.createTensorWithDataList(Int64List.fromList(inputIds), [1, inputIds.length]);
    final attentionMaskTensor = OrtValueTensor.createTensorWithDataList(
      Int64List.fromList(List.filled(inputIds.length, 1)),
      [1, inputIds.length],
    );

    final encoderOutputs = await dir.encoder.runAsync(runOptions, {
      'input_ids': inputIdsTensor,
      'attention_mask': attentionMaskTensor,
    });
    final encoderHiddenStates = encoderOutputs![0]!;

    // --- Greedy-decode, feeding the whole output sequence back each step
    //     (no KV-cache — simplest correct approach for short PTT utterances
    //     with the non-cached `decoder_model_quantized.onnx` export). ---
    const maxOutputTokens = 128;
    final outputIds = <int>[dir.decoderStartTokenId];

    for (var step = 0; step < maxOutputTokens; step++) {
      final decoderInputIdsTensor = OrtValueTensor.createTensorWithDataList(
        Int64List.fromList(outputIds),
        [1, outputIds.length],
      );

      final decoderOutputs = await dir.decoder.runAsync(runOptions, {
        'input_ids': decoderInputIdsTensor,
        'encoder_attention_mask': attentionMaskTensor,
        'encoder_hidden_states': encoderHiddenStates,
      });
      decoderInputIdsTensor.release();

      final logits = decoderOutputs![0]!.value as List; // [1, curLen, vocabSize]
      final lastStepLogits = (logits[0] as List).last as List<dynamic>;

      var bestId = 0;
      var bestScore = double.negativeInfinity;
      for (var i = 0; i < lastStepLogits.length; i++) {
        final score = (lastStepLogits[i] as num).toDouble();
        if (score > bestScore) {
          bestScore = score;
          bestId = i;
        }
      }

      for (final o in decoderOutputs) {
        o?.release();
      }

      if (bestId == dir.eosTokenId) break;
      outputIds.add(bestId);
    }

    inputIdsTensor.release();
    attentionMaskTensor.release();
    for (final o in encoderOutputs) {
      o?.release();
    }
    runOptions.release();

    // --- Decode: ids -> vocab.json pieces -> SentencePiece detokenize ---
    final generatedPieces = outputIds.skip(1).map((id) => dir.idToToken[id]).whereType<String>().toList();
    return _detokenize(generatedPieces);
  }

  /// Joins SentencePiece pieces back into text: pieces are prefixed with
  /// U+2581 ('▁') to mark a preceding space, so this is the standard
  /// SentencePiece detokenization (not something `target.spm` needs to do,
  /// since we already mapped ids back to piece strings ourselves).
  String _detokenize(List<String> pieces) {
    final joined = pieces.join();
    final withSpaces = joined.replaceAll('▁', ' ');
    return withSpaces.trim();
  }

  void dispose() {
    for (final d in _directions.values) {
      d.encoder.release();
      d.decoder.release();
    }
    _directions.clear();
    if (_envInitialized) {
      OrtEnv.instance.release();
      _envInitialized = false;
    }
  }
}
