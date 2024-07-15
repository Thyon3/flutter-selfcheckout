import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/screens/landing_page.dart';
import 'package:selfcheckoutapp/constants.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScanGo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: Constants.primaryColor,
        scaffoldBackgroundColor: Constants.backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: Constants.primaryColor,
          titleTextStyle: Constants.boldHeadingAppBar,
        ),
        cardTheme: CardTheme(
          color: Constants.cardColor,
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.cardBorderRadius),
          ),
        ),
        buttonTheme: ButtonThemeData(
          height: Constants.buttonHeight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.borderRadius),
          ),
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: Constants.primaryColor,
        scaffoldBackgroundColor: Color(0xff1a1a1a),
        appBarTheme: AppBarTheme(
          backgroundColor: Constants.primaryColor,
          titleTextStyle: Constants.boldHeadingAppBar,
        ),
        cardTheme: CardTheme(
          color: Color(0xff2a2a2a),
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.cardBorderRadius),
          ),
        ),
        buttonTheme: ButtonThemeData(
          height: Constants.buttonHeight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.borderRadius),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: LandingPage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => HomePage(),
        '/profile': (context) => ProfilePage(),
        '/cart': (context) => ShoppingCartPage(),
        '/checkout': (context) => CheckingPage(),
        '/history': (context) => BillHistoryPage(),
        '/list': (context) => ShoppingListPage(),
      },
    );
  }
}
