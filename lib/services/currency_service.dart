import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class CurrencyService {
  static const String baseUrl = 'http://your-flask-server:5000';

  Future<Map<String, dynamic>> predictCurrency(File imageFile) async {
    try {
      var uri = Uri.parse('$baseUrl/api/predict');
      var request = http.MultipartRequest('POST', uri);
      
      // Add the image file to the request
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: imageFile.path.split('/').last
      );
      request.files.add(multipartFile);

      // Send the request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse;
      } else {
        throw Exception(jsonResponse['error'] ?? 'Failed to predict currency');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }
} 