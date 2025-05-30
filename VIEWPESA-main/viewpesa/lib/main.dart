import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:viewpesa/providers/theme_provider.dart';
import 'package:viewpesa/screens/splash_screen.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'screens/login.dart';
import 'screens/profile.dart';
import 'screens/export.dart';
import 'screens/analytics.dart';
import 'screens/edittransaction.dart';
import 'screens/register.dart';
import 'screens/home.dart';
import 'screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'screens/transactionpage.dart';
//import 'services/notification_service.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.sms.request();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: ViewpesaApp(),
    ),
  );
}

class ViewpesaApp extends StatelessWidget {
  const ViewpesaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
      title: 'Viewpesa',
      theme: themeProvider.isDarkMode
          ? ThemeData.dark().copyWith(
        primaryColor: Colors.greenAccent[700],
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent[700],
            foregroundColor: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
        ),
      )
          : ThemeData(
        primaryColor: Colors.greenAccent[700],
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent[700],
            foregroundColor: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
        ),
      ),
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => LoginPage());
          case '/register':
            return MaterialPageRoute(builder: (_) => RegisterPage());
          case '/home':
            return MaterialPageRoute(
              builder: (_) => Home(),
              settings: settings, // Pass arguments for initial page
            );
          case '/profile':
            return MaterialPageRoute(builder: (_) => ViewpesaProfile());
          case '/splash':
            return MaterialPageRoute(builder:(_)=>SplashScreen());
          case '/export':
            return MaterialPageRoute(builder: (_) => ViewpesaExport());
          case '/analytics':
            return MaterialPageRoute(builder: (_) => ViewpesaAnalysis());
          case '/transactions':
            return MaterialPageRoute(builder: (_) => TransactionPage());
          case '/edit':
            return MaterialPageRoute(builder: (_) => ViewpesaEdittransaction());
          default:
            return MaterialPageRoute(builder: (_) => LoginPage());
        }
      },
    ));
  }
}