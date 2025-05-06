import 'package:flutter/material.dart';
import 'qr_generator.dart';

class QrLoginPage extends StatelessWidget {
  final String qrData;

  QrLoginPage({required this.qrData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Login"),
        backgroundColor: Colors.blue, // Cohérence de la couleur de l'AppBar
        elevation: 0, // Supprimer l'ombre sous l'AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Bienvenue ! Voici votre QR Code.",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QrGeneratorPage(data: qrData)),
                );
              },
              child: const Text("Afficher le QR Code"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Bouton de couleur bleue
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
