import 'package:dio/dio.dart';

/// A backend error mapped to something safe to surface in the UI. [statusCode] is null
/// for connectivity failures (offline), which callers use to fall back to local data.
class ApiException implements Exception {
  ApiException(this.code, this.message, {this.statusCode});

  final String code;
  final String message;
  final int? statusCode;

  bool get isNetworkError => statusCode == null;
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;

  /// Builds an [ApiException] from a Dio failure, reading the backend's
  /// `{ "error": { code, message } }` envelope when present.
  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    if (response == null) {
      return ApiException('network_error', 'No connection to the server.');
    }
    final data = response.data;
    if (data is Map && data['error'] is Map) {
      final envelope = data['error'] as Map;
      return ApiException(
        (envelope['code'] ?? 'error').toString(),
        (envelope['message'] ?? 'Request failed').toString(),
        statusCode: response.statusCode,
      );
    }
    return ApiException('error', 'Request failed', statusCode: response.statusCode);
  }
}
