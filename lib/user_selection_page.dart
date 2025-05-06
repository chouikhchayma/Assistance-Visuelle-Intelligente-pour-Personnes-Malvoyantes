import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class UserSelectionPage extends StatefulWidget {
  @override
  _UserSelectionPageState createState() => _UserSelectionPageState();
}

class _UserSelectionPageState extends State<UserSelectionPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initialize();
  }

  Future<void> _initialize() async {
    await _flutterTts.setLanguage("fr-FR"); // TTS en français
    await _startVoiceInteraction();
  }

  Future<void> _startVoiceInteraction() async {
    await _flutterTts.speak("Vous voulez vous connecter en tant qu’administrateur ou utilisateur ?");
    await Future.delayed(Duration(seconds: 3));
    _listen();
  }

  void _listen() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        localeId: "fr_FR", // Reconnaissance vocale en français
        onResult: (result) {
          String command = result.recognizedWords.toLowerCase();
          if (command.contains("admin") || command.contains("administrateur")) {
            _flutterTts.speak("Redirection vers la connexion administrateur");
            Navigator.pushNamed(context, '/admin-login');
          } else if (command.contains("utilisateur")) {
            _flutterTts.speak("Redirection vers la connexion utilisateur");
            Navigator.pushNamed(context, '/qr-scanner');
          } else {
            _flutterTts.speak("Je n’ai pas compris, veuillez répéter.");
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _startVoiceInteraction(); // Relance l'interaction vocale à chaque clic
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Sélection vocale du rôle'),
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: Container(
            padding: EdgeInsets.all(20),
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'Veuillez dire "admin" ou "utilisateur"...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ),
      ),
    );
  }


}
