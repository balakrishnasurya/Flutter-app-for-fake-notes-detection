import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';

const String flaskServerUrl = 'https://goldfish-app-ils97.ondigitalocean.app';

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
  State<CurrencyDetectionScreen> createState() =>
      _CurrencyDetectionScreenState();
}

class _CurrencyDetectionScreenState extends State<CurrencyDetectionScreen> {
  String _result = "Select or capture an image for detection";
  bool _isUploading = false;
  Uint8List? _selectedImageBytes;
  bool _imageSelected = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        Uint8List bytes;
        if (kIsWeb) {
          bytes = await image.readAsBytes();
        } else {
          bytes = await io.File(image.path).readAsBytes();
        }

        setState(() {
          _selectedImageBytes = bytes;
          _imageSelected = true;
          _result = "Image selected. Click Process to analyze.";
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        _result =
            "Error accessing ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e";
      });
    }
  }

  Future<void> _processImage() async {
    if (!_imageSelected || _selectedImageBytes == null) {
      setState(() {
        _result = "Please select or capture an image first";
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _result = "Processing image...";
    });

    try {
      var uri = Uri.parse('$flaskServerUrl/api/predict');
      var request = http.MultipartRequest('POST', uri);

      request.files.add(http.MultipartFile.fromBytes(
          'image', _selectedImageBytes!,
          filename: 'image.jpg', contentType: MediaType('image', 'jpeg')));

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
Denomination Confidence: ${(jsonResponse['denomination']['confidence'] * 100).toStringAsFixed(2)}%
''';
          });
        } else {
          setState(() {
            _result = "Error: ${jsonResponse['message'] ?? 'Unknown error'}";
          });
        }
      } else {
        setState(() {
          _result =
              "Error: Server returned ${response.statusCode}\nResponse: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _result = "Error processing image: $e";
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isUploading
                      ? null
                      : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
                ElevatedButton.icon(
                  onPressed: _isUploading
                      ? null
                      : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
              ],
            ),
            if (_imageSelected) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _processImage,
                icon: const Icon(Icons.analytics),
                label: const Text('Process Image'),
              ),
            ],
            const SizedBox(height: 20),
            if (_isUploading)
              const Center(child: CircularProgressIndicator())
            else
              SelectableText(_result),
            if (_selectedImageBytes != null) ...[
              const SizedBox(height: 20),
              Image.memory(_selectedImageBytes!),
            ],
          ],
        ),
      ),
    );
  }
}
