import 'package:flutter_test/flutter_test.dart';
import 'package:countdown/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const CountdownApp());
    expect(find.text('COUNTDOWN'), findsOneWidget);
  });
}
