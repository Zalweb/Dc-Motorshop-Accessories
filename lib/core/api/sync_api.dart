import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_exception.dart';

class SyncPullResult {
  SyncPullResult({required this.changes, required this.tombstones, required this.serverTime});

  final List<Map<String, dynamic>> changes;
  final List<String> tombstones;
  final DateTime serverTime;
}

/// Phase-2 delta sync transport: pull changes/tombstones since a timestamp, push upserts.
class SyncApi {
  SyncApi(this._client);

  final ApiClient _client;
  Dio get _dio => _client.dio;

  Future<SyncPullResult> pull(String table, {DateTime? since}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/sync/$table',
        queryParameters: {
          if (since != null) 'since': since.toUtc().toIso8601String(),
        },
      );
      final data = res.data!;
      return SyncPullResult(
        changes: List<Map<String, dynamic>>.from(data['changes'] as List),
        tombstones: List<String>.from(data['tombstones'] as List),
        serverTime: DateTime.parse(data['server_time'] as String),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, int>> push(String table, List<Map<String, dynamic>> rows) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/sync/$table', data: {'rows': rows});
      return Map<String, int>.from(res.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
