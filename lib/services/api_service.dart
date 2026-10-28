import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/environmental_data.dart';
import '../models/classification_result.dart';
import '../core/constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal();

  final http.Client _client = http.Client();

  Map<String, String> _headers([String? contentType]) {
    return {
      'X-API-Key': ApiConstants.apiKey,
      if (contentType != null) 'Content-Type': contentType,
    };
  }

  // Health check
  Future<bool> healthCheck() async {
    try {
      final response = await _client
          .get(
            Uri.parse(ApiConstants.healthCheck),
            headers: _headers(),
          )
          .timeout(ApiConstants.connectTimeout);

      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  // Get current environmental data
  Future<EnvironmentalData?> getEnvironmentalData() async {
    try {
      final response = await _client
          .get(
            Uri.parse(ApiConstants.environmental),
            headers: _headers(),
          )
          .timeout(ApiConstants.receiveTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return EnvironmentalData.fromJson(json['data']);
      }

      return null;
    } catch (e) {
      print('Error fetching environmental data: $e');
      return null;
    }
  }

  // Get environmental data history
  Future<List<EnvironmentalData>> getEnvironmentalHistory({
    int limit = 10,
  }) async {
    try {
      final url = Uri.parse(
        ApiConstants.environmentalHistory,
      ).replace(
        queryParameters: {'limit': limit.toString()},
      );

      final response = await _client
          .get(url, headers: _headers())
          .timeout(ApiConstants.receiveTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] as List;

        return data
            .map((item) => EnvironmentalData.fromJson(item))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error fetching environmental history: $e');
      return [];
    }
  }

  // Download image from Raspberry Pi camera
  Future<List<int>?> downloadImageFromRPI(String filename) async {
    try {
      final response = await _client
          .get(
            Uri.parse(
              '${ApiConstants.baseUrl}/api/camera/image/$filename',
            ),
            headers: _headers(),
          )
          .timeout(ApiConstants.receiveTimeout);

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }

      return null;
    } catch (e) {
      print('Error downloading image from RPI: $e');
      return null;
    }
  }

  // Upload exported report/file to Raspberry Pi
  Future<String?> uploadExport({
    required String filename,
    required List<int> bytes,
    required String contentType,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(ApiConstants.exports).replace(
              queryParameters: {'filename': filename},
            ),
            headers: _headers(contentType),
            body: bytes,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body =
            jsonDecode(response.body) as Map<String, dynamic>;

        if (body['success'] != true ||
            body['verified'] != true) {
          throw Exception(
            'Old RPi backend at ${ApiConstants.baseUrl}. '
            'Update api_server.py and restart the backend.',
          );
        }

        return body['filepath'] as String?;
      }

      throw Exception(
        'RPi returned ${response.statusCode}: ${response.body}',
      );
    } catch (e) {
      print('Error uploading export to RPI: $e');
      rethrow;
    }
  }

  // Get all classifications
  Future<List<ClassificationResult>> getClassifications() async {
    try {
      final response = await _client
          .get(
            Uri.parse(ApiConstants.classificationsAll),
            headers: _headers(),
          )
          .timeout(ApiConstants.receiveTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] as List;

        return data
            .map((item) => ClassificationResult.fromJson(item))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error fetching classifications: $e');
      return [];
    }
  }

  // Send batch update to API
  Future<bool> sendBatchUpdate({
    required String batchId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(
              '${ApiConstants.baseUrl}/api/batch/update',
            ),
            headers: _headers('application/json'),
            body: jsonEncode({
              ...data,
              'batch_id': batchId,
            }),
          )
          .timeout(ApiConstants.connectTimeout);

      print(
        'Batch update: ${response.statusCode} ${response.body}',
      );

      return response.statusCode == 200 ||
          response.statusCode == 201;
    } catch (e) {
      print('Error sending batch update: $e');
      return false;
    }
  }

  // Start batch on Raspberry Pi using the same batch ID
  Future<bool> startBatch({
    required String batchId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(
              '${ApiConstants.baseUrl}/api/batch/start',
            ),
            headers: _headers('application/json'),
            body: jsonEncode({
              ...data,
              'batch_id': batchId,
              'batch_name': data['name'],
              'start_time': data['startDate'],
            }),
          )
          .timeout(ApiConstants.connectTimeout);

      print(
        'Start batch: ${response.statusCode} ${response.body}',
      );

      return response.statusCode == 200 ||
          response.statusCode == 201;
    } catch (e) {
      print('Error starting batch: $e');
      return false;
    }
  }

  // Send alert to API
  Future<bool> sendAlert({
    required String alertId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(
              '${ApiConstants.baseUrl}/api/alert/send',
            ),
            headers: _headers('application/json'),
            body: jsonEncode({
              'alert_id': alertId,
              ...data,
            }),
          )
          .timeout(ApiConstants.connectTimeout);

      print(
        'Send alert: ${response.statusCode} ${response.body}',
      );

      return response.statusCode == 200 ||
          response.statusCode == 201;
    } catch (e) {
      print('Error sending alert: $e');
      return false;
    }
  }

  // Get latest quality assessment result
  Future<Map<String, dynamic>?> getLatestQuality() async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConstants.baseUrl}/api/quality/latest'),
            headers: _headers(),
          )
          .timeout(ApiConstants.receiveTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      print('Error fetching latest quality: $e');
      return null;
    }
  }

  // Get active batch
  Future<Map<String, dynamic>?> getActiveBatch() async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConstants.baseUrl}/api/batch/active'),
            headers: _headers(),
          )
          .timeout(ApiConstants.receiveTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      print('Error fetching active batch: $e');
      return null;
    }
  }

  // Get batch history
  Future<List<Map<String, dynamic>>> getBatchHistory() async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConstants.baseUrl}/api/batch/history'),
            headers: _headers(),
          )
          .timeout(ApiConstants.receiveTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] as List;
        return data.cast<Map<String, dynamic>>();
      }

      return [];
    } catch (e) {
      print('Error fetching batch history: $e');
      return [];
    }
  }
}