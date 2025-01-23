import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
// import 'package:object_detection_app/CapturedImageScreen.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'CapturedImageScreen.dart';

class CameraScreen extends StatefulWidget {
  final String objectName;
  final List<CameraDescription> cameras;

  CameraScreen({required this.objectName, required this.cameras});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  bool _isDetecting = false;

  Interpreter? _interpreter;
  List<dynamic>? _recognitions;
  bool _isObjectDetected = false;
  CameraImage? _capturedImage; // Change type to CameraImage
  String? _capturedImagePath;
  late String _message; // Remove the initial assignment here
  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
    _message = "Detecting ${widget.objectName}";
  }

  void _initializeCamera() {
    _controller = CameraController(widget.cameras[0], ResolutionPreset.medium);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _controller.startImageStream((CameraImage image) {
        if (!_isDetecting) {
          _isDetecting = true;
          _runModel(image);
        }
      });
    });
  }

  Future<void> _loadModel() async {
    try {
      _interpreter =
          await Interpreter.fromAsset('assets/models/converted_model.tflite');
      print("Model loaded successfully.");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  void _runModel(CameraImage image) async {
    if (_interpreter == null) return;

    try {
      final input = _preprocessImage(image, 300, 300);

      var output = List.filled(10 * 4, 0).reshape([1, 10, 4]);

      _interpreter!.run(input, output);

      setState(() {
        _recognitions = output;
        _message = "Detecting ${widget.objectName}";
      });

      _handleDetection(image, output); // Pass image directly for handling
    } catch (e) {
      print("Error during model inference: $e");
    } finally {
      _isDetecting = false;
    }
  }

  List<List<List<List<int>>>> _preprocessImage(
      CameraImage image, int inputWidth, int inputHeight) {
    List<List<List<List<int>>>> input = List.generate(
      1,
      (_) => List.generate(inputHeight,
          (_) => List.generate(inputWidth, (_) => List.generate(3, (_) => 0))),
    );

    final int width = image.width;
    final int height = image.height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int uvIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);

        int yPixel = image.planes[0].bytes[y * width + x];
        int uPixel = image.planes[1].bytes[uvIndex];
        int vPixel = image.planes[2].bytes[uvIndex];

        int r = (yPixel + 1.402 * (vPixel - 128)).clamp(0, 255).toInt();
        int g = (yPixel - 0.34414 * (uPixel - 128) - 0.71414 * (vPixel - 128))
            .clamp(0, 255)
            .toInt();
        int b = (yPixel + 1.772 * (uPixel - 128)).clamp(0, 255).toInt();

        int resizedY = ((y / height) * inputHeight).floor();
        int resizedX = ((x / width) * inputWidth).floor();
        input[0][resizedY][resizedX] = [r, g, b];
      }
    }
    return input;
  }

  void _handleDetection(CameraImage image, dynamic output) {
    if (output != null && output.isNotEmpty) {
      setState(() {
        _isObjectDetected = true;
        _message = "Object detected!";
      });

      // Auto-capture when object is detected
      if (_isObjectDetected) {
        // Capture the current camera image from the stream (not the preview size)
        _capturedImage = image; // Capture the image directly
        _capturedImagePath =
            "captured_image_${DateTime.now().millisecondsSinceEpoch}.jpg";
        _navigateToNextScreen();
      }
    } else {
      setState(() {
        _isObjectDetected = false;
        _message = "No object detected";
      });
    }
  }

  void _navigateToNextScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CapturedImageScreen(
            image: _capturedImage!, objectType: widget.objectName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text("Detect ${widget.objectName}")),
      body: Stack(
        children: [
          CameraPreview(_controller),
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: EdgeInsets.all(10),
              color: Colors.black54,
              child: Text(
                _message,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _interpreter?.close();
    super.dispose();
  }
}
