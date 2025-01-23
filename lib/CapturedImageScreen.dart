// import 'package:camera/camera.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CapturedImageScreen extends StatelessWidget {
  final CameraImage image;
  final String objectType;

  const CapturedImageScreen({required this.image, required this.objectType});

  @override
  Widget build(BuildContext context) {
    // Your widget code here
    return Scaffold(
      appBar: AppBar(title: Text("Captured Image")),
      body: Center(child: Text("Captured image of $objectType")),
    );
  }
}
