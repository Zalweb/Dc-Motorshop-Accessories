import 'package:dc_motorcycle_inventory/core/api/api_client.dart';
import 'package:dc_motorcycle_inventory/core/api/secure_token_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory token store for tests.
class FakeTokenStore implements TokenStore {
  String? access;
  String? refresh;
  bool cleared = false;

  @override
  Future<String?> accessToken() async => access;

  @override
  Future<String?> refreshToken() async => refresh;

  @override
  Future<bool> hasSession() async => refresh != null;

  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
    cleared = true;
  }
}

/// Dio adapter that:
///  - answers `/auth/refresh` with a fresh token pair, and
///  - answers `/protected` with 200 only when the bearer is the refreshed token,
///    otherwise 401 — so the client must refresh and retry to succeed.
class _FakeAdapter implements HttpClientAdapter {
  int refreshCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/auth/refresh') {
      refreshCalls++;
      return ResponseBody.fromString(
        '{"access_token":"new-access","refresh_token":"new-refresh","expires_in":900}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    final auth = options.headers['Authorization'];
    if (auth == 'Bearer new-access') {
      return ResponseBody.fromString('{"ok":true}', 200, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });
    }
    return ResponseBody.fromString('{"error":{"code":"unauthorized"}}', 401, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  ApiClient build(FakeTokenStore store) {
    final adapter = _FakeAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final bare = Dio()..httpClientAdapter = adapter;
    return ApiClient(store: store, dio: dio, bareDio: bare);
  }

  test('a 401 triggers a refresh and the retried request succeeds', () async {
    final store = FakeTokenStore()
      ..access = 'old-access'
      ..refresh = 'old-refresh';
    final client = build(store);

    final response = await client.dio.get<Map<String, dynamic>>('/protected');

    expect(response.statusCode, 200);
  });

  test('refresh stores the rotated tokens', () async {
    final store = FakeTokenStore()
      ..access = 'old-access'
      ..refresh = 'old-refresh';
    final client = build(store);

    await client.dio.get<Map<String, dynamic>>('/protected');

    expect(store.refresh, 'new-refresh');
  });

  test('without a refresh token the 401 is surfaced', () async {
    final store = FakeTokenStore()..access = 'old-access';
    final client = build(store);

    await expectLater(
      client.dio.get<Map<String, dynamic>>('/protected'),
      throwsA(isA<DioException>()),
    );
  });
}
