import 'package:flutter_test/flutter_test.dart';
import 'package:gopal_app/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const GopalApp());

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
  });
}
