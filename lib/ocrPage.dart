import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OCRApp());
}

class OCRApp extends StatelessWidget {
  const OCRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const CameraTextDetection(),
    );
  }
}

class TextDetection {
  final String text;
  final DateTime timestamp;

  TextDetection(this.text, this.timestamp);
}

class CameraTextDetection extends StatefulWidget {
  const CameraTextDetection({super.key});

  @override
  _CameraTextDetectionState createState() => _CameraTextDetectionState();
}

class _CameraTextDetectionState extends State<CameraTextDetection> {
  CameraController? _controller;
  final TextRecognizer _textRecognizer = TextRecognizer();
  final FlutterTts _flutterTts = FlutterTts();
  List<TextDetection> _detectedTexts = [];
  bool _isProcessing = false;
  Timer? _captureTimer;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("fr-FR");
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _initializeCamera() async {
    if (await Permission.camera.request().isGranted) {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _controller = CameraController(
          cameras[0],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _controller!.initialize();
        await _controller!.setFlashMode(FlashMode.off); // Désactivation du flash ici
        if (!mounted) return;

        setState(() {});

        _captureTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
          _captureAndRecognizeText();
        });
      }
    }
  }

  Future<void> _captureAndRecognizeText() async {
    if (_isProcessing || _controller == null || !_controller!.value.isInitialized) return;

    _isProcessing = true;
    try {
      final XFile imageFile = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      List<String> newTexts = recognizedText.text
          .split('\n')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      if (_isTextUnique(newTexts)) {
        setState(() {
          final timestamp = DateTime.now();
          for (var newText in newTexts) {
            _detectedTexts.insert(0, TextDetection(newText, timestamp));
          }
        });
        _speakText(newTexts.join('. '));
      }
    } catch (e) {
      print("Erreur de traitement : $e");
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _speakText(String text) async {
    if (!_isSpeaking && text.isNotEmpty) {
      try {
        _isSpeaking = true;
        await _flutterTts.speak(text);
        await _flutterTts.awaitSpeakCompletion(true);
      } catch (e) {
        print("Erreur de synthèse vocale : $e");
      } finally {
        _isSpeaking = false;
      }
    }
  }

  bool _isTextUnique(List<String> newTexts) {
    DateTime now = DateTime.now();
    if (_detectedTexts.isEmpty) return true;

    final recentTexts = _detectedTexts
        .where((t) => now.difference(t.timestamp).inSeconds < 1)
        .map((t) => t.text.toLowerCase())
        .toList();

    for (var newText in newTexts) {
      final normalizedNew = newText.toLowerCase();
      if (recentTexts.any((t) => t.contains(normalizedNew) || normalizedNew.contains(t))) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _controller?.dispose();
    _textRecognizer.close();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détection et Lecture de Texte'),
        actions: [
          IconButton(
            icon: Icon(_isSpeaking ? Icons.volume_off : Icons.volume_up),
            onPressed: () => _isSpeaking ? _flutterTts.stop() : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: _controller?.value.isInitialized ?? false
                ? CameraPreview(_controller!)
                : const Center(child: CircularProgressIndicator()),
          ),
          Expanded(
            flex: 1,
            child: _detectedTexts.isEmpty
                ? const Center(child: Text("Aucun texte détecté"))
                : ListView.builder(
              reverse: true,
              itemCount: _detectedTexts.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(
                  _detectedTexts[index].text,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Détecté à ${_detectedTexts[index].timestamp.hour}:${_detectedTexts[index].timestamp.minute}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
