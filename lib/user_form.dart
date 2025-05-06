import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:ocr/qr_login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class UserForm extends StatefulWidget {
  @override
  _UserFormState createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child("users");

  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();

    _tts.setLanguage("fr-FR");

    _startForm();
  }

  Future<void> _startForm() async {
    await _speakAndWait("Veuillez dire votre nom");
    _listenForField(_nameController, onDone: () async {
      await _speakAndWait("Veuillez dire votre prénom");
      _listenForField(_surnameController, onDone: () async {
        await _speakAndWait("Veuillez dire votre Gmail");
        _listenForField(_emailController, onDone: () async {
          _processEmail();
          await _speakAndWait("Votre email est enregistré comme ${_emailController.text}");
          _saveUser();
        });
      });
    });
  }

  void _processEmail() {
    String raw = _emailController.text.trim().toLowerCase();

    // Supprimer les espaces
    raw = raw.replaceAll(' ', '');

    // Supprimer @ ou tout ce qui vient après si l'utilisateur les a dit
    if (raw.contains("@")) {
      raw = raw.split("@")[0];
    }

    _emailController.text = "$raw@gmail.com";
  }

  Future<void> _speakAndWait(String text) async {
    bool speaking = true;
    _tts.setCompletionHandler(() {
      speaking = false;
    });

    await _tts.speak(text);

    while (speaking) {
      await Future.delayed(Duration(milliseconds: 200));
    }

    await Future.delayed(Duration(milliseconds: 500));
  }

  void _listenForField(TextEditingController controller, {required Function onDone}) async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        listenMode: stt.ListenMode.dictation,
        localeId: 'fr_FR',
        onResult: (result) async {
          if (result.finalResult) {
            controller.text = result.recognizedWords;
            _speech.stop();
            setState(() => _isListening = false);
            await Future.delayed(Duration(milliseconds: 500));
            onDone();
          }
        },
        pauseFor: Duration(seconds: 10),
      );
    } else {
      await _tts.speak("Le service de reconnaissance vocale n'est pas disponible.");
    }
  }

  Future<void> _saveUser() async {
    String name = _nameController.text.trim();
    String surname = _surnameController.text.trim();
    String email = _emailController.text.trim();

    if (name.isNotEmpty && surname.isNotEmpty && email.isNotEmpty) {
      String userId = _dbRef.push().key!;
      final String qrCodeData = "$name $surname";

      await _dbRef.child(userId).set({
        'name': name,
        'surname': surname,
        'email': email,
        'qrCode': qrCodeData,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstLaunch', false);

      await _tts.speak("Merci. Vos informations ont été enregistrées.");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => QrLoginPage(qrData: qrCodeData)),
      );
    } else {
      await _tts.speak("Certains champs sont vides. Veuillez recommencer.");
      _startForm();
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Formulaire vocal"),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Veuillez remplir les informations suivantes :',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 20),
              _buildTextField(_nameController, 'Nom'),
              _buildTextField(_surnameController, 'Prénom'),
              _buildTextField(_emailController, 'Email', keyboardType: TextInputType.emailAddress),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveUser,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  backgroundColor: Colors.blue,
                  textStyle: TextStyle(fontSize: 16),
                ),
                child: Text("Enregistrer"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
        ),
        keyboardType: keyboardType,
      ),
    );
  }
}
