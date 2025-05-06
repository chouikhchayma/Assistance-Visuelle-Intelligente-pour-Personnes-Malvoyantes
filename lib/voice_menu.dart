import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'navigation.dart';  // Ensure this import is correct for your NavigationPage
import 'ocrPage.dart';     // Ensure this import is correct for your OCRApp
import 'ObjectDetection.dart';  // Ensure this import is correct for your ObjectDetectionPage

class VoiceOptionsScreen extends StatefulWidget {
  @override
  _VoiceOptionsScreenState createState() => _VoiceOptionsScreenState();
}

class _VoiceOptionsScreenState extends State<VoiceOptionsScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();
  bool _isSpeaking = false;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    welcomeUser();
  }

  Future<void> welcomeUser() async {
    if (_isSpeaking) return;
    _isSpeaking = true;

    await flutterTts.setLanguage("fr-FR");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);

    final List<String> messages = [
      "Bienvenue dans notre application.",
      "Il y a trois choix :",
      "Aller vers une destination.",
      "Connaître un objet.",
      "Lire un texte.",
      "Veuillez dire votre choix maintenant."
    ];

    for (String msg in messages) {
      await flutterTts.speak(msg);
      await flutterTts.awaitSpeakCompletion(true);
    }

    _isSpeaking = false;
    listenUserChoice();
  }

  void listenUserChoice() async {
    bool available = await speech.initialize(
      onStatus: (status) {
        if (status == 'done' && _retryCount < 2) {
          _retryCount++;
          flutterTts.speak("Je n'ai pas compris. Veuillez répéter.");
          listenUserChoice();
        }
      },
      onError: (error) {
        flutterTts.speak("Erreur lors de l'écoute. ${error.errorMsg}");
      },
    );

    if (available) {
      speech.listen(
        listenMode: stt.ListenMode.dictation,
        localeId: "fr_FR",
        onResult: (result) {
          if (result.finalResult) {
            String choice = result.recognizedWords.toLowerCase();
            handleVoiceCommand(choice);
          }
        },
      );
    } else {
      await flutterTts.speak("Le service de reconnaissance vocale n'est pas disponible.");
    }
  }

  void handleVoiceCommand(String command) async {
    print("Commande reconnue : $command");

    if (command.contains('destination')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => NavigationPage()));
    } else if (command.contains('objet')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => Objectdetection()));
    } else if (command.contains('texte')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => OCRApp()));
    } else {
      await flutterTts.speak("Option non reconnue. Veuillez répéter.");
      listenUserChoice();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Menu Vocal"),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hearing, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                '🎤 Écoute en cours...',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Veuillez dire l\'une des options suivantes :\n\n'
                    '➡️ "Destination"\n'
                    '➡️ "Objet"\n'
                    '➡️ "Texte"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.mic),
                label: const Text("Répéter la question"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  _retryCount = 0;
                  welcomeUser();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
