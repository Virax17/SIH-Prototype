enum MsgDir { sent, recv }

class Message {
  final int id;
  final MsgDir dir;
  final String tag;
  final String text;

  Message({required this.id, required this.dir, required this.tag, required this.text});
}

class LangOption {
  final String code;
  final String native;
  final String latin;
  final String glyph;
  final String? glyphFontFamily;

  const LangOption({
    required this.code,
    required this.native,
    required this.latin,
    required this.glyph,
    this.glyphFontFamily,
  });
}

const kLangs = [
  LangOption(code: 'EN', native: 'English', latin: 'English', glyph: 'A'),
  LangOption(code: 'HI', native: 'हिन्दी', latin: 'Hindi', glyph: 'अ', glyphFontFamily: 'NotoSansDevanagari'),
  LangOption(code: 'TA', native: 'தமிழ்', latin: 'Tamil', glyph: 'அ', glyphFontFamily: 'NotoSansTamil'),
];

enum DeviceLinkState { connected, available, failed }

class DeviceInfo {
  final String name;
  final String status;
  final DeviceLinkState state;
  final int bars;

  const DeviceInfo({required this.name, required this.status, required this.state, required this.bars});
}
