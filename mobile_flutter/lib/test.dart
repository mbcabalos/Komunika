import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GestureDetectorScreen extends StatefulWidget {
  @override
  _GestureDetectorScreenState createState() => _GestureDetectorScreenState();
}

class _GestureDetectorScreenState extends State<GestureDetectorScreen> {
  File? _image;
  String _prediction = "No gesture detected";

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      _sendImageToServer(_image!);
    }
  }

  Future<void> _sendImageToServer(File imageFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse("http://192.168.1.133:5000/gesture/detect"), // Adjust URL if needed
    );

    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    var decodedData = jsonDecode(responseData);

    setState(() {
      _prediction = decodedData['label'] ?? "Error detecting gesture";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gesture Detector")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? Image.file(_image!, height: 300)
                : Text("No image selected"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text("Capture Image"),
            ),
            SizedBox(height: 20),
            Text("Prediction: $_prediction", style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
