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

  const Message({
    required this.id,
    required this.dir,
    required this.phraseIdx,
    required this.lang,
    this.playing = false,
  });

  Message copyWith({bool? playing}) => Message(
        id: id,
        dir: dir,
        phraseIdx: phraseIdx,
        lang: lang,
        playing: playing ?? this.playing,
      );
}

enum DeviceStatus { connected, available, outOfRange, connecting }

class BtDevice {
  final int id;
  final String name;
  final DeviceStatus status;

  const BtDevice({required this.id, required this.name, required this.status});

  BtDevice copyWith({DeviceStatus? status}) => BtDevice(id: id, name: name, status: status ?? this.status);
}

enum ScriptMode { both, native, latin }
