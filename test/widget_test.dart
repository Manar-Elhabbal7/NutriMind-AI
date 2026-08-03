import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mind/main.dart';
import 'package:nutri_mind/features/splash/splash_view.dart';

void main() {
  testWidgets('App launches and displays SplashView', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that SplashView is present.
    expect(find.byType(SplashView), findsOneWidget);

    // Let the navigation timer fire and settle to avoid pending timer errors
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
