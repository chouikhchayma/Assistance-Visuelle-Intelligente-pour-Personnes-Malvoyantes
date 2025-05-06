import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ocr/controller/detection_controller.dart';

class StreamDetectionPage extends GetView<DetectionController> {
  const StreamDetectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    List<Widget> renderBoxes(Size screen) {
      if (controller.imageHeight.value == 0.0 ||
          controller.imageWidth.value == 0.0) return [];

      double factorX = screen.width;
      double factorY = screen.height;
      Color blue = const Color.fromRGBO(37, 213, 253, 1.0);

      return controller.recognitions.map<Widget>((re) {
        if ((re["confidenceInClass"] as double) >= 0.3) {
          return Positioned(
            left: re["rect"]["x"] * factorX,
            top: re["rect"]["y"] * factorY,
            width: re["rect"]["w"] * factorX,
            height: re["rect"]["h"] * factorY,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: blue, width: 2),
              ),
              child: Text(
                "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(1)}%",
                style: TextStyle(
                  background: Paint()..color = blue,
                  color: Colors.white,
                  fontSize: 12.0,
                ),
              ),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Stream Detection"),
      ),
      body: Obx(() => controller.isInitialized.value
          ? Stack(
        children: [
          CameraPreview(controller.cameraController),
          ...renderBoxes(size),
        ],
      )
          : const Center(
        child: CircularProgressIndicator(),
      )),
    );
  }
}
