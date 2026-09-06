enum LangCode { en, hi, ta }

extension LangCodeX on LangCode {
  String get nativeName {
    switch (this) {
      case LangCode.en:
        return 'English';
      case LangCode.hi:
        return 'हिन्दी';
      case LangCode.ta:
        return 'தமிழ்';
    }
  }

  String get latinName {
    switch (this) {
      case LangCode.en:
        return 'English';
      case LangCode.hi:
        return 'Hindi';
      case LangCode.ta:
        return 'Tamil';
    }
  }

  String? get glyphFontFamily {
    switch (this) {
      case LangCode.en:
        return null;
      case LangCode.hi:
        return 'NotoSansDevanagari';
      case LangCode.ta:
        return 'NotoSansTamil';
    }
  }
}

class Phrase {
  final String native;
  final String latin;
  const Phrase({required this.native, required this.latin});
}

enum MsgDir { sent, received }

class Message {
  final int id;
  final MsgDir dir;
  final int phraseIdx;
  final LangCode lang;
  final bool playing;

  /// Set when this message was typed by hand rather than spoken (or
  /// simulated from [kPhrases]) — shown verbatim instead of looking up a
  /// canned phrase by [phraseIdx].
  final String? customText;

  const Message({
    required this.id,
    required this.dir,
    required this.phraseIdx,
    required this.lang,
    this.playing = false,
    this.customText,
  });

  Message copyWith({bool? playing}) => Message(
        id: id,
        dir: dir,
        phraseIdx: phraseIdx,
        lang: lang,
        playing: playing ?? this.playing,
        customText: customText,
      );
}

enum ScriptMode { both, native, latin }

/// A permanent local record of a government emergency broadcast that was
/// sent or received. Never auto-deleted — the log is the point.
class EmergencyAlertRecord {
  final int id;
  final MsgDir dir;
  final String native;
  final String latin;
  final DateTime timestamp;

  const EmergencyAlertRecord({
    required this.id,
    required this.dir,
    required this.native,
    required this.latin,
    required this.timestamp,
  });

  factory EmergencyAlertRecord.fromJson(Map<String, dynamic> j) => EmergencyAlertRecord(
        id: j['id'] as int,
        dir: MsgDir.values.byName(j['dir'] as String),
        native: j['native'] as String,
        latin: j['latin'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'dir': dir.name,
        'native': native,
        'latin': latin,
        'timestamp': timestamp.toIso8601String(),
      };
}
