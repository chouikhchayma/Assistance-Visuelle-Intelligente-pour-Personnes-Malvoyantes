import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:tflite_v2/tflite_v2.dart';

class DetectionController extends GetxController {
  late CameraController cameraController;
  Rx<bool> isInitialized = Rx(false);
  RxString result = "".obs;
  bool isprocessing = false;
  RxDouble imageHeight = 0.0.obs;
  RxDouble imageWidth = 0.0.obs;
  RxList recognitions = [].obs;
  final FlutterTts flutterTts = FlutterTts();

  List<Map<String, dynamic>> recentDetections = [];

  @override
  void onInit() async {
    await loadDataModel();
    await initializeCamera();
    super.onInit();
  }

  @override
  void onClose() {
    cameraController.dispose();
    super.onClose();
  }

  Future loadDataModel() async {
    await Tflite.loadModel(
      model: "assets/ssd_mobilenet.tflite",
      labels: "assets/ssd_mobilenet.txt",
    );
  }

  Future initializeCamera() async {
    final cameras = await availableCameras();
    cameraController = CameraController(
      cameras[0],
      ResolutionPreset.medium,
    );
    await cameraController.initialize();
    isInitialized.value = true;

    if (Get.arguments['type'] == "streaming") {
      cameraController.startImageStream(ssDrunModeOnStreamFram);
    }
  }

  ssDrunModeOnStreamFram(CameraImage img) async {
    if (isprocessing) return;
    isprocessing = true;
    await Future.delayed(const Duration(milliseconds: 100));

    result.value = "";
    try {
      imageHeight.value = img.height.toDouble();
      imageWidth.value = img.width.toDouble();
      final now = DateTime.now();

      var rawDetections = await Tflite.detectObjectOnFrame(
        bytesList: img.planes.map((plan) => plan.bytes).toList(),
        model: 'SSDMobileNet',
        imageHeight: img.height,
        imageWidth: img.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResultsPerClass: 2,
        threshold: 0.1,
        asynch: true,
      );

      if (rawDetections != null) {
        recentDetections.removeWhere(
              (d) => now.difference(d["timestamp"]).inSeconds > 1,
        );

        List filtered = [];
        for (var detection in rawDetections) {
          String className = detection["detectedClass"];
          double confidence = detection["confidenceInClass"];
          Map box = detection["rect"];

          bool isDuplicate = recentDetections.any((d) =>
          d["class"] == className &&
              _isSimilarBox(d["box"], box) &&
              now.difference(d["timestamp"]).inMilliseconds < 800);

          if (!isDuplicate && confidence >= 0.3) {
            recentDetections.add({
              "class": className,
              "box": box,
              "timestamp": now,
            });
            filtered.add(detection);
          }
        }

        recognitions.value = filtered;
      }
    } catch (e) {
      print("Erreur détection stream : $e");
    } finally {
      isprocessing = false;
    }
  }

  bool _isSimilarBox(Map a, Map b, {double threshold = 0.1}) {
    double dx = (a["x"] - b["x"]).abs();
    double dy = (a["y"] - b["y"]).abs();
    double dw = (a["w"] - b["w"]).abs();
    double dh = (a["h"] - b["h"]).abs();
    return dx < threshold && dy < threshold && dw < threshold && dh < threshold;
  }

  Future<void> takePicture() async {
    try {
      var file = await cameraController.takePicture();
      File image = File(file.path);

      if (isprocessing) return;
      isprocessing = true;

      await Future.delayed(const Duration(seconds: 1));
      result.value = '';

      var recognitions = await Tflite.detectObjectOnImage(
        path: image.path,
        numResultsPerClass: 1,
      );

      if (recognitions != null) {
        String spokenText = "Les objets devant toi sont : ";
        int count = 0;

        for (var recognition in recognitions) {
          String objectName = recognition["detectedClass"];
          double confidence = recognition["confidenceInClass"];
          String line = "$objectName - ${confidence.toStringAsFixed(2)}";
          result.value += "$line\n";

          if (count < 2) {
            spokenText += "$objectName, ";
            count++;
          }
        }

        spokenText = spokenText.trim().replaceAll(RegExp(r',$'), '.');

        await flutterTts.setLanguage("fr-FR");
        await flutterTts.setSpeechRate(0.5);
        await flutterTts.speak(spokenText);
      }
    } catch (e) {
      print("Erreur lors de la détection : $e");
    } finally {
      isprocessing = false;
    }
  }
}
