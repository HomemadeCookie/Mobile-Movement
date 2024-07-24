import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  late CameraController _controller;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );

    try {
      await _controller.initialize();
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _controller == null
            ? CircularProgressIndicator()
            : CameraPreview(_controller),
      ),
    );
  }
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Mobile Movement'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  late CameraController _controller; // Declare the camera controller
  Uint8List? _capturedImageData;
  String? _lastCapturedImagePath;

  Future<void> _sendImageToApi() async {
    if (_capturedImageData == null) {
      print('No image captured yet');
      return;
    }

    final url = Uri.parse('http://192.168.67.164:5000/upload');  // for emulator
    // OR
    // final url = Uri.parse('http://YOUR_COMPUTER_IP:5000/upload');  // for physical device
    
    try {
      print('Preparing to send image to API');
      var request = http.MultipartRequest('POST', url);
      
      print('Adding image to request');
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        _capturedImageData!,
        filename: 'image.jpg',
      ));

      print('Sending request to API');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Received response from API');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Image uploaded successfully');
        // You can show a success message to the user here
      } else {
        print('Failed to upload image. Status code: ${response.statusCode}');
        // You can show an error message to the user here
      }
    } catch (e) {
      print('Error sending image to API: $e');
      // You can show an error message to the user here
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );

    try {
      await _controller.initialize();
    } catch (e) {
      print(e);
    }

    setState(() {}); // Trigger a rebuild after camera initialization
  }

  Future<void> _captureImage() async {
    try {
      final image = await _controller.takePicture();
      if (kIsWeb) {
        // For web platform
        final imageData = await image.readAsBytes();
        setState(() {
          _capturedImageData = imageData;
          _lastCapturedImagePath = null;  // Web doesn't use file paths
        });
      } else {
        // For mobile platforms
        setState(() {
          _capturedImageData = File(image.path).readAsBytesSync();
          _lastCapturedImagePath = image.path;
        });
      }
    } catch (e) {
      print('Error capturing image: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: _controller.value.isInitialized
                ? CameraPreview(_controller)
                : CircularProgressIndicator(),
          ),
          if (_capturedImageData != null)
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: kIsWeb
                        ? Image.memory(_capturedImageData!)
                        : Image.file(File(_lastCapturedImagePath!)),
                  ),
                  ElevatedButton(
                    onPressed: _sendImageToApi,
                    child: Text('Send to API'),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _controller.value.isInitialized ? _captureImage : null,
        tooltip: 'Capture Image',
        child: const Icon(Icons.camera),
      ),
    );
  }
}
