import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;

const String flaskServerUrl = 'http://127.0.0.1:5000';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Detection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const CurrencyDetectionScreen(),
    );
  }
}

class CurrencyDetectionScreen extends StatefulWidget {
  const CurrencyDetectionScreen({super.key});

  @override
  State<CurrencyDetectionScreen> createState() => _CurrencyDetectionScreenState();
}

class _CurrencyDetectionScreenState extends State<CurrencyDetectionScreen> {
  String _result = "Upload an image for detection";
  bool _isUploading = false;
  String _edgeImageBase64 = '';
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _uploadImage(io.File(image.path));
    }
  }

  Future<void> _uploadImage(io.File imageFile) async {
    setState(() {
      _isUploading = true;
      _result = "Processing image...";
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$flaskServerUrl/api/predict'));
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      
      request.files.add(
        http.MultipartFile(
          'image',
          stream,
          length,
          filename: 'image.jpg',
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          setState(() {
            _result = '''
Authenticity: ${jsonResponse['authenticity']['prediction']}
Confidence: ${(jsonResponse['authenticity']['confidence'] * 100).toStringAsFixed(2)}%
Denomination: ${jsonResponse['denomination']['prediction']}
''';
            _edgeImageBase64 = jsonResponse['edge_image'];
          });
        } else {
          setState(() {
            _result = "Error: ${jsonResponse['message']}";
          });
        }
      } else {
        setState(() {
          _result = "Error: Server returned ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _result = "Error: Failed to connect to server - $e";
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Detection'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isUploading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _pickAndUploadImage,
                child: const Text('Select Image'),
              ),
            const SizedBox(height: 20),
            Text(_result),
            if (_edgeImageBase64.isNotEmpty) ...[
              const SizedBox(height: 20),
              Image.memory(base64Decode(_edgeImageBase64)),
            ],
          ],
        ),
      ),
    );
  }
}
