import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';

class Objectdetection extends StatefulWidget {
  @override
  _ObjectdetectionState createState() => _ObjectdetectionState();
}

class _ObjectdetectionState extends State<Objectdetection> {
  File? _image;
  List<String> _labels = [];
  bool _loading = false;

  final String _visionApiKey = 'AIzaSyC5rRtAdLVX9UexKZ0k_rjNR6GqVZwKDe8';
  final String _translateApiKey = 'AIzaSyC5rRtAdLVX9UexKZ0k_rjNR6GqVZwKDe8';
  FlutterTts _flutterTts = FlutterTts();

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedImage == null) return;

    setState(() {
      _image = File(pickedImage.path);
      _labels = [];
    });

    await _detectObjects(_image!);
  }

  Future<void> _detectObjects(File imageFile) async {
    setState(() => _loading = true);

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final url = Uri.parse(
        'https://vision.googleapis.com/v1/images:annotate?key=$_visionApiKey');

    final body = jsonEncode({
      "requests": [
        {
          "image": {"content": base64Image},
          "features": [
            {"type": "LABEL_DETECTION", "maxResults": 10}
          ],
          "imageContext": {
            "languageHints": ["fr"]
          }
        }
      ]
    });

    final response = await http.post(url, body: body, headers: {
      'Content-Type': 'application/json',
    });

    final data = jsonDecode(response.body);
    final labels = data['responses'][0]['labelAnnotations'] as List<dynamic>;

    String mostRelevantLabel = '';
    double highestConfidence = 0.0;

    for (var label in labels) {
      double confidence = label['score'] ?? 0.0;
      if (confidence > highestConfidence) {
        highestConfidence = confidence;
        mostRelevantLabel = label['description'] as String;
      }
    }

    String translatedLabel = await _translateToFrench(mostRelevantLabel);

    setState(() {
      _labels = [translatedLabel];
      _loading = false;
    });

    if (translatedLabel.isNotEmpty) {
      await _flutterTts.setLanguage('fr-FR');
      await _flutterTts.speak("L'objet détecté est $translatedLabel");
    }
  }

  Future<String> _translateToFrench(String text) async {
    final translateUrl = Uri.parse(
        'https://translation.googleapis.com/language/translate/v2?key=$_translateApiKey');

    final response = await http.post(translateUrl, body: jsonEncode({
      'q': text,
      'target': 'fr',
    }), headers: {
      'Content-Type': 'application/json',
    });

    final data = jsonDecode(response.body);
    return data['data']['translations'][0]['translatedText'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Détection d'objets")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.camera_alt),
              label: Text("Prendre une photo"),
            ),
            SizedBox(height: 20),
            if (_image != null) Image.file(_image!, height: 200),
            SizedBox(height: 20),
            if (_loading)
              CircularProgressIndicator()
            else if (_labels.isNotEmpty)
              Text("Objet détecté: ${_labels[0]}")
          ],
        ),
      ),
    );
  }
}