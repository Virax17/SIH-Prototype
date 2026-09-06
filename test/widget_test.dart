import 'package:flutter_test/flutter_test.dart';

import 'package:itantra/main.dart';

void main() {
  testWidgets('iTantra home screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ITantraApp());
    await tester.pump();

    expect(find.text('Hold to talk'), findsOneWidget);
  });
}
