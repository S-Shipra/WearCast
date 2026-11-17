import 'package:flutter/foundation.dart';

/// Shared API configuration for development, emulators, and deployed builds.
///
/// Override with `--dart-define=WEARCAST_API_URL=https://api.example.com/api`.
const String _configuredApiBaseUrl = String.fromEnvironment('WEARCAST_API_URL');

String get apiBaseUrl {
  if (_configuredApiBaseUrl.isNotEmpty) return _configuredApiBaseUrl;
  // Android emulators reach the host machine through 10.0.2.2.
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:5000/api';
  }
  return 'http://localhost:5000/api';
}

Uri apiUri(String path, [Map<String, String>? queryParameters]) {
  final base = Uri.parse(apiBaseUrl);
  return base.replace(
    path: '${base.path.replaceFirst(RegExp(r'/$'), '')}/$path',
    queryParameters: queryParameters,
  );
}

Map<String, String> apiHeaders({String? token, bool json = false}) => {
  if (json) 'Content-Type': 'application/json',
  if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
};
