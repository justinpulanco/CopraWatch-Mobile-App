import 'package:flutter_test/flutter_test.dart';
import 'package:copra_watch/core/constants/api_constants.dart';

void main() {
  test('updates the API base URL with an IP and port', () {
    ApiConstants.updateBaseUrl('192.168.254.199', 5000);

    expect(ApiConstants.baseUrl, 'http://192.168.254.199:5000');
    expect(ApiConstants.healthCheck, contains('/api/health'));
  });
}
