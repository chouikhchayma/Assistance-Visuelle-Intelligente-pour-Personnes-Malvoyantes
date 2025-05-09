import 'package:ocr/controller/detection_controller.dart';
import 'package:get/get.dart';

class DetectionBinding extends Bindings{
  @override
  void dependencies() {
    Get.lazyPut(() => DetectionController());
  }
}