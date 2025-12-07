import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CaptureScreen(),
    );
  }
}

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});
  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  CameraController? controller;
  Timer? timer;
  int intervalSeconds = 5;
  bool running = false;

  @override
  void initState() {
    super.initState();
    controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );
    controller!.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  void startCapture() {
    running = true;
    timer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) async {
      if (!controller!.value.isInitialized) return;

      final file = await controller!.takePicture();
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = '${dir.path}/img_$timestamp.jpg';
      await File(file.path).copy(newPath);
    });
  }

  void stopCapture() {
    timer?.cancel();
    running = false;
  }

  @override
  void dispose() {
    controller?.dispose();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Dataset Collector")),
      body: Column(
        children: [
          CameraPreview(controller!),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: "Interval (seconds)"),
              onChanged: (val) {
                intervalSeconds = int.tryParse(val) ?? 5;
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: running ? null : startCapture,
                child: const Text("Start"),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: running ? stopCapture : null,
                child: const Text("Stop"),
              )
            ],
          )
        ],
      ),
    );
  }
}
