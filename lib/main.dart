import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:http_parser/http_parser.dart';

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
  String _result = "Upload an image for detection";
  bool _isUploading = false;
  String _edgeImageBase64 = '';
  String _originalImageBase64 = '';
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadImage() async {
    setState(() {
      _isUploading = true;
      _result = "Processing image...";
    });

    try {
      if (kIsWeb) {
        final html.FileUploadInputElement input = html.FileUploadInputElement()
          ..accept = 'image/*';
        input.click();

        try {
          await input.onChange.first;
          if (input.files!.isNotEmpty) {
            final reader = html.FileReader();
            reader.readAsDataUrl(input.files![0]);
            final dataUrl = await reader.onLoad.first;
            final originalBase64 = (reader.result as String).split(',')[1];

            final arrayReader = html.FileReader();
            arrayReader.readAsArrayBuffer(input.files![0]);
            await arrayReader.onLoad.first;
            final bytes = arrayReader.result as List<int>;

            var uri = Uri.parse('$flaskServerUrl/api/predict');
            var request = http.MultipartRequest('POST', uri);

            var multipartFile = http.MultipartFile.fromBytes('image', bytes,
                filename: 'image.jpg', contentType: MediaType('image', 'jpeg'));

            request.files.add(multipartFile);

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
Message: ${jsonResponse['message']}
''';
                  _originalImageBase64 = originalBase64;
                  if (jsonResponse['edge_image'] != null) {
                    _edgeImageBase64 = jsonResponse['edge_image'];
                  }
                });
              } else {
                setState(() {
                  _result =
                      "Error: ${jsonResponse['message'] ?? 'Unknown error'}";
                });
              }
            } else {
              setState(() {
                _result =
                    "Error: Server returned ${response.statusCode}\nResponse: ${response.body}";
              });
            }
          }
        } catch (e, stackTrace) {
          print('Error during file processing: $e');
          print('Stack trace: $stackTrace');
          setState(() {
            _result = "Error processing file: $e";
          });
        }
      } else {
        // Mobile image picking
        final XFile? image =
            await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          await _uploadImage(io.File(image.path));
        }
      }
    } catch (e, stackTrace) {
      print('Error in _pickAndUploadImage: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _result = "Error: Failed to process image - $e";
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _uploadImage(io.File imageFile) async {
    setState(() {
      _isUploading = true;
      _result = "Processing image...";
    });

    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('$flaskServerUrl/api/predict'));
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
Authenticity: ${jsonResponse['authenticity_prediction']}
Confidence: ${(jsonResponse['authenticity_confidence'] * 100).toStringAsFixed(2)}%
Denomination: ${jsonResponse['denomination_prediction']}
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
      print('Error details: $e');
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
            SelectableText(_result),
            if (_originalImageBase64.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Original Image:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Image.memory(base64Decode(_originalImageBase64)),
            ],
            if (_edgeImageBase64.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Edge Detection:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Image.memory(base64Decode(_edgeImageBase64)),
            ],
          ],
        ),
      ),
    );
  }
}
