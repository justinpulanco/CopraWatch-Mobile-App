import 'dart:convert';
import 'package:http/http.dart' as http;

class PiService {
  static const String baseUrl = 'http://192.168.254.198:5000';

  static Future<String> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
      );

      if (response.statusCode == 200) {
        return 'Raspberry Pi connected!';
      } else {
        return 'Pi responded: ${response.statusCode}';
      }
    } catch (e) {
      return 'Pi connection failed: $e';
    }
  }
}