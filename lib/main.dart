import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:ocr/pages/home_page.dart';
import 'admin_login.dart';
import 'admin_dashboard.dart';
import 'voice_menu.dart';
import 'view_users_page.dart';
import 'user_selection_page.dart';
import 'qr_login_page.dart';
import 'user_form.dart';
import 'qr_scanner_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

  runApp(MyApp(isFirstLaunch: isFirstLaunch));
}

class MyApp extends StatelessWidget {
  final bool isFirstLaunch;

  const MyApp({super.key, required this.isFirstLaunch}); // 👈 Ajoute super.key

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp( // Remplacement de MaterialApp par GetMaterialApp
      title: 'Login App',
      debugShowCheckedModeBanner: false,
      initialRoute: isFirstLaunch ? '/user-form' : '/',
      routes: {
        '/': (context) => UserSelectionPage(),
        '/admin-login': (context) => AdminLoginPage(),
        '/admin-dashboard': (context) => AdminDashboard(),
        '/view-users': (context) => ViewUsersPage(),
        '/voice-options': (context) => VoiceOptionsScreen(),
        '/user-form': (context) => UserForm(),
        '/qr-login': (context) => QrLoginPage(qrData: ''),
        '/qr-scanner': (context) => QrScannerPage(),
        '/home': (context) => HomePage(),

      },
    );
  }
}
