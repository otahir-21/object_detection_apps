import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';

import 'CameraScreen.dart';

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(ObjectDetectionApp());
}

class ObjectDetectionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ObjectSelectionScreen(),
    );
  }
}

class ObjectSelectionScreen extends StatelessWidget {
  final List<String> objects = ["Laptop", "Mobile", "Mouse", "Bottle"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select an Object")),
      body: ListView.builder(
        itemCount: objects.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(objects[index]),
            onTap: () {
              // Pass selected object to the next screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CameraScreen(
                    objectName: objects[index],
                    cameras: cameras!, // Pass cameras to CameraScree
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
