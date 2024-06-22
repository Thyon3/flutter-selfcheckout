import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:selfcheckoutapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('Complete user flow from login to checkout', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Verify landing page
      expect(find.text('Welcome Shopper!'), findsOneWidget);
      expect(find.text('Login to your account'), findsOneWidget);

      // Navigate to registration
      await tester.tap(find.text('Create New Account'));
      await tester.pumpAndSettle();

      // Fill registration form
      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.pumpAndSettle();

      // Submit registration
      await tester.tap(find.text('Create New Account'));
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Should return to login (or go to home if auto-login works)
      // Test continues based on app behavior

      // Fill login form
      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.pumpAndSettle();

      // Submit login
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Verify home screen
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('What do you want to do?'), findsOneWidget);
    });

    testWidgets('Shopping list functionality', (WidgetTester tester) async {
      // Launch app and login (simplified for integration test)
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Navigate to shopping list
      await tester.tap(find.text('Create a Shopping List'));
      await tester.pumpAndSettle();

      // Verify shopping list screen
      expect(find.text('Shopping List'), findsOneWidget);

      // Add new item
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Enter item name
      await tester.enterText(find.byType(TextField), 'Milk');
      await tester.pumpAndSettle();

      // Save item
      await tester.tap(find.text('ADD'));
      await tester.pumpAndSettle();

      // Verify item added
      expect(find.text('Milk'), findsOneWidget);
    });

    testWidgets('Shopping cart flow', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Navigate to shopping cart
      await tester.tap(find.text("Let's Start Shopping!"));
      await tester.pumpAndSettle();

      // Verify shopping cart screen
      expect(find.text('Shopping Cart'), findsOneWidget);

      // Test empty cart message
      expect(find.text('No items in cart.'), findsOneWidget);
      expect(find.text('Scan items to start!'), findsOneWidget);
    });

    testWidgets('Navigation flow test', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Test navigation to different screens
      await tester.tap(find.text('Create a Shopping List'));
      await tester.pumpAndSettle();
      expect(find.text('Shopping List'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      await tester.tap(find.text('Check Cart History'));
      await tester.pumpAndSettle();
      expect(find.text('Cart History'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('App drawer functionality', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Open app drawer
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // Verify drawer options
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('About App'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);

      // Test close drawer
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });
  });
}
