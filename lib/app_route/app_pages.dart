import 'package:flutter/material.dart';
import 'package:ocr/binding/detection_binding.dart';
import 'package:ocr/pages/detection_page.dart';
import 'package:ocr/app_route/app_routes.dart';
import 'package:ocr/pages/home_page.dart';
import 'package:get/route_manager.dart';
import 'package:ocr/pages/detection_page.dart';
import 'package:ocr/pages/stream_detection_page.dart';


class AppPages {
  static final pages = [
    GetPage(
        name: AppRoutes.homePage,
        page: () => const HomePage()
    ),
    GetPage(
      binding:DetectionBinding() ,
      name: AppRoutes.detectionPage,
      page: () => const DetectPicture(),
    ),
    GetPage(
        binding:DetectionBinding(),
        name: AppRoutes.streamPage,
        page: () => const StreamDetectionPage()
    ),
  ];
}