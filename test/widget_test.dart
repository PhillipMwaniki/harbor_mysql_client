import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_mysql_client/main.dart';

void main() {
  testWidgets('App starts and shows welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const HarborApp());

    // Verify the welcome screen is shown
    expect(find.text('Welcome to Harbor'), findsOneWidget);
    expect(find.text('New Connection'), findsOneWidget);
  });
}
