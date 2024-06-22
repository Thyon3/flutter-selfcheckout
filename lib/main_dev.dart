import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:selfcheckoutapp/screens/landing_page.dart';
import 'package:selfcheckoutapp/services/analytics_service.dart';
import 'package:selfcheckoutapp/services/monitoring_service.dart';
import 'package:selfcheckoutapp/services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await AnalyticsService().initialize();
  await MonitoringService().initialize();
  await SessionService().initialize();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
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
        primaryColor: Color(0xff1faa00),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        primaryColor: Color(0xff1faa00),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      themeMode: ThemeMode.system,
      home: LandingPage(),
    );
  }
}
