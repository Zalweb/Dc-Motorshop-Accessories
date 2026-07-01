import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_exception.dart';

/// Sales are server-authoritative (the server recomputes totals), so offline sales are
/// replayed through the idempotent `POST /sales` rather than the generic sync push.
class SalesApi {
  SalesApi(this._client);

  final ApiClient _client;
  Dio get _dio => _client.dio;

  Future<void> checkout(Map<String, dynamic> sale) async {
    try {
      await _dio.post<Map<String, dynamic>>('/sales', data: sale);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
