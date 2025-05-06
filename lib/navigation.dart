import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

class NavigationPage extends StatefulWidget {
  @override
  _NavigationPageState createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  late GoogleMapController _mapController;
  LatLng? _currentPosition;
  Set<Polyline> _polylines = {};
  late FlutterTts _tts;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  TextEditingController _destinationController = TextEditingController();
  final String apiKey = "AIzaSyC5rRtAdLVX9UexKZ0k_rjNR6GqVZwKDe8"; // Remplacez par votre clé API Google Maps

  List<Map<String, dynamic>> _navigationSteps = [];
  int _currentStepIndex = 0;
  StreamSubscription<Position>? _positionSubscription;
  LatLng? _destination;
  Timer? _instructionTimer;
  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == 'done') {
          setState(() => _isListening = false);
        }
      },
      onError: (val) => print('Erreur: $val'),
    );
    if (available) {
      setState(() => _isListening = true);
      await _speech.listen(
        localeId: "fr_FR",
        onResult: (result) {
          String spokenText = result.recognizedWords;
          _destinationController.text = spokenText;
          _getRoute(spokenText);
        },
      );
    } else {
      await _speak("La reconnaissance vocale n'est pas disponible.");
    }
  }

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _speech = stt.SpeechToText();
    _initialize();
  }

  Future<void> _initialize() async {
    await _speak("dites votre destination.");
    await _getCurrentLocation();

    // Start listening automatically after initialization
    await _startListening();
  }



  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled) {
      await _speak("Les services de localisation sont désactivés.");
      return;
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
        await _speak("Permission de localisation non accordée.");
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _getRoute(String destinationName) async {
    if (_currentPosition == null || destinationName.trim().isEmpty) {
      await _speak("Veuillez fournir une destination valide.");
      return;
    }

    await _positionSubscription?.cancel();
    _instructionTimer?.cancel();

    final geocodeUrl =
        "https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(destinationName)}&key=$apiKey";
    final geocodeRes = await http.get(Uri.parse(geocodeUrl));
    final geocodeData = json.decode(geocodeRes.body);

    if (geocodeData['results'].isEmpty) {
      await _speak("Destination introuvable.");
      return;
    }

    final dest = geocodeData['results'][0]['geometry']['location'];
    _destination = LatLng(dest['lat'], dest['lng']);

    final routeUrl =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${_currentPosition!.latitude},${_currentPosition!.longitude}&destination=${_destination!.latitude},${_destination!.longitude}&mode=walking&key=$apiKey";
    final routeRes = await http.get(Uri.parse(routeUrl));
    final routeData = json.decode(routeRes.body);

    if (routeData['routes'].isEmpty) {
      await _speak("Aucun itinéraire trouvé.");
      return;
    }

    final points = routeData['routes'][0]['overview_polyline']['points'];
    final decodedPolyline = _decodePolyline(points);

    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: PolylineId("route"),
          points: decodedPolyline,
          color: Colors.blue,
          width: 6,
        ),
      );
    });

    final leg = routeData['routes'][0]['legs'][0];
    final distanceText = leg['distance']['text'];
    await _speak("Itinéraire vers $destinationName démarré. Distance : $distanceText.");

    _navigationSteps.clear();
    _currentStepIndex = 0;

    final steps = leg['steps'];
    for (var step in steps) {
      _navigationSteps.add({
        'instruction': step['html_instructions'].replaceAll(RegExp(r'<[^>]*>'), ''),
        'start_lat': step['start_location']['lat'],
        'start_lng': step['start_location']['lng'],
        'end_lat': step['end_location']['lat'],
        'end_lng': step['end_location']['lng'],
      });
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position pos) {
      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
      });
      _checkProximityToStep(pos);
    });

    _instructionTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _repeatCurrentInstruction();
    });
  }


  Future<void> _repeatCurrentInstruction() async {
    if (_currentStepIndex < _navigationSteps.length) {
      final currentStep = _navigationSteps[_currentStepIndex];
      String instruction = currentStep['instruction'].toLowerCase();
      String basicInstruction;

      if (instruction.contains("left")) {
        basicInstruction = "Tournez à gauche";
      } else if (instruction.contains("right")) {
        basicInstruction = "Tournez à droite";
      } else if (instruction.contains("straight") || instruction.contains("head")) {
        basicInstruction = "Allez tout droit";
      } else if (instruction.contains("back")) {
        basicInstruction = "Faites demi-tour";
      } else {
        basicInstruction = "Continuez";
      }

      final double distanceToEnd = Geolocator.distanceBetween(
        _currentPosition?.latitude ?? 0,
        _currentPosition?.longitude ?? 0,
        currentStep['end_lat'],
        currentStep['end_lng'],
      );

      String finalInstruction = "$basicInstruction sur ${distanceToEnd.toStringAsFixed(0)} mètres.";
      await _speak(finalInstruction);
    }
  }

  void _checkProximityToStep(Position position) async {
    if (_currentStepIndex >= _navigationSteps.length) return;

    final currentStep = _navigationSteps[_currentStepIndex];
    final double distanceToStart = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      currentStep['start_lat'],
      currentStep['start_lng'],
    );

    final double distanceToEnd = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      currentStep['end_lat'],
      currentStep['end_lng'],
    );

    if (distanceToStart < 20) {
      String instruction = currentStep['instruction'].toLowerCase();
      String basicInstruction;

      if (instruction.contains("left")) {
        basicInstruction = "Tournez à gauche";
      } else if (instruction.contains("right")) {
        basicInstruction = "Tournez à droite";
      } else if (instruction.contains("straight") || instruction.contains("head")) {
        basicInstruction = "Allez tout droit";
      } else if (instruction.contains("back")) {
        basicInstruction = "Faites demi-tour";
      } else {
        basicInstruction = "Continuez";
      }

      String? prochainTour;
      if (_currentStepIndex + 1 < _navigationSteps.length) {
        final nextInstruction = _navigationSteps[_currentStepIndex + 1]['instruction'].toLowerCase();
        if (nextInstruction.contains("left")) {
          prochainTour = "puis tournez à gauche";
        } else if (nextInstruction.contains("right")) {
          prochainTour = "puis tournez à droite";
        } else if (nextInstruction.contains("back")) {
          prochainTour = "puis faites demi-tour";
        } else if (nextInstruction.contains("straight") || nextInstruction.contains("head")) {
          prochainTour = "puis allez tout droit";
        }
      }

      String finalInstruction = "$basicInstruction sur ${distanceToEnd.toStringAsFixed(0)} mètres";
      if (prochainTour != null) {
        finalInstruction += ", $prochainTour.";
      } else {
        finalInstruction += ".";
      }

      await _speak(finalInstruction);
      _currentStepIndex++;
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }

  Future<void> _speak(String text) async {
    await _tts.setLanguage("fr-FR");
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _instructionTimer?.cancel();
    _tts.stop();
    _speech.stop();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Navigation pour non-voyants")),
      body: Stack(
        children: [
          _currentPosition == null
              ? Center(child: CircularProgressIndicator())
              : GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentPosition!, zoom: 15),
            myLocationEnabled: true,
            onMapCreated: (controller) => _mapController = controller,
            polylines: _polylines,
          ),
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: Column(
              children: [
                TextField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    labelText: "Entrez ou dites la destination",
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) => _getRoute(value),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _getRoute(_destinationController.text),
                      child: Text("Démarrer"),
                    ),
                    IconButton(
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                      onPressed: _startListening,
                      tooltip: "Commande vocale",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
