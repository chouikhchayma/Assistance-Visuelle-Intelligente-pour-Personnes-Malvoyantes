import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ocr/app_route/app_routes.dart'; // Import your routes file

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome"),
      ),
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Get.toNamed(AppRoutes.streamPage, arguments: {"type": "streaming"});
              },
              child: const Text("Start Detection"),
            ),
            ElevatedButton(
              onPressed: () {
                Get.toNamed(AppRoutes.detectionPage, arguments: {"type": "picture"});
              },
              child: const Text("Take Picture"),
            ),
          ],
        ),
      ),
    );
  }
}
