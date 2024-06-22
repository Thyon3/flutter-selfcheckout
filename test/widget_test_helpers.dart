import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfcheckoutapp/screens/login.dart';
import 'package:selfcheckoutapp/screens/register.dart';
import 'package:selfcheckoutapp/screens/home.dart';
import 'package:selfcheckoutapp/screens/shopping_cart.dart';
import 'package:selfcheckoutapp/widgets/custom_button.dart';
import 'package:selfcheckoutapp/widgets/custom_input.dart';

// Widget testing helpers
class WidgetTestHelpers {
  // Find common widgets by type and key
  static Finder findCustomButton({String? text}) {
    if (text != null) {
      return find.widgetWithText(CustomBtn, text);
    }
    return find.byType(CustomBtn);
  }

  static Finder findCustomInput({String? hintText}) {
    if (hintText != null) {
      return find.byWidgetPredicate((widget) =>
          widget is CustomInput && widget.hintText == hintText);
    }
    return find.byType(CustomInput);
  }

  static Finder findAppBarTitle(String title) {
    return find.byWidgetPredicate((widget) =>
        widget is AppBar && widget.title is Text && 
        (widget.title as Text).data == title);
  }

  // Common test scenarios
  static Future<void> fillLoginForm(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    await tester.enterText(find.byKey(Key('email_field')), email);
    await tester.enterText(find.byKey(Key('password_field')), password);
    await tester.pump();
  }

  static Future<void> fillRegistrationForm(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    await tester.enterText(find.byKey(Key('reg_email_field')), email);
    await tester.enterText(find.byKey(Key('reg_password_field')), password);
    await tester.pump();
  }

  static Future<void> tapButton(WidgetTester tester, String buttonText) async {
    await tester.tap(find.text(buttonText));
    await tester.pumpAndSettle();
  }

  static Future<void> tapCustomButton(WidgetTester tester, String buttonText) async {
    await tester.tap(findCustomButton(text: buttonText));
    await tester.pumpAndSettle();
  }

  // Navigation helpers
  static Future<void> navigateToLogin(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();
  }

  static Future<void> navigateToRegister(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: RegisterPage()));
    await tester.pumpAndSettle();
  }

  static Future<void> navigateToHome(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();
  }

  static Future<void> navigateToShoppingCart(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: ShoppingCartPage()));
    await tester.pumpAndSettle();
  }

  // Assertion helpers
  static void expectTextOnScreen(String text) {
    expect(find.text(text), findsOneWidget);
  }

  static void expectTextNotOnScreen(String text) {
    expect(find.text(text), findsNothing);
  }

  static void expectButtonExists(String buttonText) {
    expect(find.text(buttonText), findsOneWidget);
  }

  static void expectCustomButtonExists(String buttonText) {
    expect(findCustomButton(text: buttonText), findsOneWidget);
  }

  static void expectInputFieldExists(String hintText) {
    expect(findCustomInput(hintText: hintText), findsOneWidget);
  }

  // Loading state helpers
  static void expectLoadingIndicator() {
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  }

  static void expectNoLoadingIndicator() {
    expect(find.byType(CircularProgressIndicator), findsNothing);
  }

  // Error dialog helpers
  static void expectErrorDialog() {
    expect(find.byType(AlertDialog), findsOneWidget);
  }

  static Future<void> dismissDialog(WidgetTester tester) async {
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }
}

// Test material app wrapper
class TestApp extends StatelessWidget {
  final Widget home;
  final String? title;

  const TestApp({Key? key, required this.home, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title ?? 'Test App',
      home: home,
      debugShowCheckedModeBanner: false,
    );
  }
}
