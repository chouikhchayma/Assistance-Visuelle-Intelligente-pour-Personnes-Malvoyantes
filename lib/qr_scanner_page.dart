import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:firebase_database/firebase_database.dart';

class QrScannerPage extends StatefulWidget {
  @override
  _QrScannerPageState createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child("users");

  bool _isChecking = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController ctrl) {
    this.controller = ctrl;
    ctrl.scannedDataStream.listen((scanData) async {
      if (_isChecking) return;
      _isChecking = true;

      final String scannedData = scanData.code ?? '';

      // Vérification dans la base de données Firebase
      final snapshot = await _dbRef.get();

      bool userFound = false;

      if (snapshot.exists) {
        final users = snapshot.value as Map;

        users.forEach((key, value) {
          if (value['qrCode'] == scannedData) {
            userFound = true;
          }
        });
      }

      if (userFound) {
        controller?.pauseCamera(); // Pause la caméra après le scan réussi
        Navigator.pushReplacementNamed(context, '/voice-options'); // Rediriger vers la page de l'option vocale
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR Code invalide')),
        );
        _isChecking = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scanner le QR Code"),
        backgroundColor: Colors.blue, // Cohérence de la couleur de l'AppBar
        elevation: 0, // Supprimer l'ombre sous l'AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  'Scannez votre QR Code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
