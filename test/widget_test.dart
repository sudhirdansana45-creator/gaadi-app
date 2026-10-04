import 'package:flutter_test/flutter_test.dart';
import 'package:gaadi_manager/main.dart';

void main() {
  testWidgets('App loads cleanly test', (WidgetTester tester) async {
    await tester.pumpWidget(const GaadiManagerApp());
    expect(find.byType(GaadiManagerApp), findsOneWidget);
  });
}
