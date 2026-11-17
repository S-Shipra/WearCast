import 'dart:convert';

import 'package:http/http.dart' as http;

class LocationService {
  // 1. Auto-detect via IP (Default)
  static Future<Map<String, dynamic>> getCurrentLocation() async {
    try {
      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final city = data['city'] ?? 'Unknown';
        final region = data['region'] ?? '';
        final country = data['country_name'] ?? '';

        String fullLocation = city;
        if (region.isNotEmpty && region != city) fullLocation += ', $region';
        if (country.isNotEmpty) fullLocation += ', $country';

        return {
          'city': fullLocation,
          'lat': data['latitude'] ?? 19.0760,
          'lon': data['longitude'] ?? 72.8777,
        };
      }
    } catch (_) {
      // Location is optional; use the city fallback if the lookup is unavailable.
    }
    return {'city': 'Mumbai, India', 'lat': 19.0760, 'lon': 72.8777};
  }

  // 2. Manual City Search
  static Future<Map<String, dynamic>?> searchCity(String cityName) async {
    try {
      final url = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': cityName,
        'count': '1',
        'language': 'en',
        'format': 'json',
      });
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          String label = result['name'];
          if (result['admin1'] != null) label += ', ${result['admin1']}';

          return {
            'city': label,
            'lat': result['latitude'],
            'lon': result['longitude'],
          };
        }
      }
    } catch (_) {
      // The caller presents a retryable "city not found" message.
    }
    return null;
  }
}
