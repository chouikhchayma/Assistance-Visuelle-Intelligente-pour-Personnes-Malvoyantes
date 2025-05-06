// initial_qr_wrapper.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'qr_generator.dart';

class InitialQrGeneratorWrapper extends StatefulWidget {
  @override
  _InitialQrGeneratorWrapperState createState() => _InitialQrGeneratorWrapperState();
}

class _InitialQrGeneratorWrapperState extends State<InitialQrGeneratorWrapper> {
  @override
  void initState() {
    super.initState();
    _completeAndRedirect();
  }

  Future<void> _completeAndRedirect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false); // Marque comme lancé
    await Future.delayed(Duration(seconds: 3)); // Affiche 3 secondes
    Navigator.pushReplacementNamed(context, '/'); // Redirige vers accueil
  }

  @override
  Widget build(BuildContext context) {
    final String userData = "id:1234;name:Chayma";
    return QrGeneratorPage(data: userData); // Affiche QR
  }
}
