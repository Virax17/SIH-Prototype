import 'package:flutter_test/flutter_test.dart';

import 'package:itantra/main.dart';
import 'package:itantra/services/stt_service.dart';
import 'package:itantra/services/tts_service.dart';

void main() {
  testWidgets('iTantra home screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(ITantraApp(stt: SttService(), tts: TtsService()));
    await tester.pump();

    expect(find.text('Hold to talk'), findsOneWidget);
  });
}
