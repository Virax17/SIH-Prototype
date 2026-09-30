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

/// Real delivery state of a [MsgDir.sent] message, driven by the Bluetooth
/// send + ack round trip (see `BluetoothManager.sendText`/`messageAcked`) —
/// not a fixed animation.
enum DeliveryStatus { sending, delivered }

class Message {
  final int id;
  final MsgDir dir;
  final LangCode lang;
  final bool playing;

  /// The real recognized/translated (or typed) text of this message, in
  /// [lang]. This is what's displayed and what gets spoken by TTS on replay.
  final String text;

  /// Set for [MsgDir.sent] messages once they've actually been written to
  /// the connection; null for received messages (delivery is meaningless
  /// from the receiving side).
  final DeliveryStatus? delivery;

  const Message({
    required this.id,
    required this.dir,
    required this.lang,
    required this.text,
    this.playing = false,
    this.delivery,
  });

  Message copyWith({bool? playing, DeliveryStatus? delivery}) => Message(
        id: id,
        dir: dir,
        lang: lang,
        text: text,
        playing: playing ?? this.playing,
        delivery: delivery ?? this.delivery,
      );
}

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
