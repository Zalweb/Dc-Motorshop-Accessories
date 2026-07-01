import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_exception.dart';

/// Calls the tenant backup endpoints (full snapshot export + idempotent import).
class BackupApi {
  BackupApi(this._client);

  final ApiClient _client;
  Dio get _dio => _client.dio;

  Future<Map<String, dynamic>> export() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/backup/export');
      return res.data!;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, int>> import(Map<String, dynamic> snapshot) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/backup/import', data: snapshot);
      return Map<String, int>.from(res.data!['imported'] as Map);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
