import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/environmental_data.dart';
import '../models/classification_result.dart';
import '../core/constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  final http.Client _client = http.Client();

  // Health check
  Future<bool> healthCheck() async {
    try {
      final response = await _client
          .get(Uri.parse(ApiConstants.healthCheck))
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
          .get(Uri.parse(ApiConstants.environmental))
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
  Future<List<EnvironmentalData>> getEnvironmentalHistory({int limit = 10}) async {
    try {
      final url = Uri.parse(ApiConstants.environmentalHistory).replace(
        queryParameters: {'limit': limit.toString()},
      );

      final response = await _client
          .get(url)
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

  // Get all classifications
  Future<List<ClassificationResult>> getClassifications() async {
    try {
      final response = await _client
          .get(Uri.parse(ApiConstants.classificationsAll))
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

  // Send classification to API
  Future<bool> sendClassification({
    required int imageId,
    required String classification,
    required double confidence,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(ApiConstants.classification),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'image_id': imageId,
              'classification': classification,
              'confidence': confidence,
            }),
          )
          .timeout(ApiConstants.connectTimeout);

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending classification: $e');
      return false;
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
            Uri.parse('${ApiConstants.baseUrl}/api/batch/update'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'batch_id': batchId,
              ...data,
            }),
          )
          .timeout(ApiConstants.connectTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error sending batch update: $e');
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
            Uri.parse('${ApiConstants.baseUrl}/api/alert/send'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'alert_id': alertId,
              ...data,
            }),
          )
          .timeout(ApiConstants.connectTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error sending alert: $e');
      return false;
    }
  }
}
