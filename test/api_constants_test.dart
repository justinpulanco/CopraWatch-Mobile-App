import 'package:flutter_test/flutter_test.dart';
import 'package:copra_watch/core/constants/api_constants.dart';

void main() {
  test('updates the API base URL with HTTPS for an IP and port', () {
    ApiConstants.updateBaseUrl('192.168.254.199', 5000);

    expect(ApiConstants.baseUrl, 'https://192.168.254.199:5000');
    expect(ApiConstants.healthCheck, contains('/api/health'));
  });

  test('does not allow an HTTP input to downgrade the API URL', () {
    ApiConstants.updateBaseUrl('http://coprawatch.example.test', 5000);

    expect(ApiConstants.baseUrl, 'https://coprawatch.example.test:5000');
  });
}
