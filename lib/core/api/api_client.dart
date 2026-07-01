import 'package:dio/dio.dart';

import 'secure_token_store.dart';

/// Default base URL. `10.0.2.2` is the Android emulator's alias for the host
/// machine's localhost; override at build time with
/// `--dart-define=API_BASE_URL=https://api.example.com/v1`.
const String kDefaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/v1',
);

/// Wraps a configured Dio with:
///  - an auth interceptor that attaches the access token, and
///  - a 401 interceptor that refreshes the token once and retries the request.
///
/// Refresh + retry use a bare Dio (no interceptors) to avoid recursion. When the
/// refresh token itself is rejected, tokens are cleared and [onSessionExpired] fires.
class ApiClient {
  ApiClient({
    required this.store,
    String baseUrl = kDefaultApiBaseUrl,
    this.onSessionExpired,
    Dio? dio,
    Dio? bareDio,
  })  : dio = dio ?? Dio(),
        _bare = bareDio ?? Dio() {
    for (final client in [this.dio, _bare]) {
      client.options
        ..baseUrl = baseUrl
        ..connectTimeout = const Duration(seconds: 10)
        ..receiveTimeout = const Duration(seconds: 20)
        ..headers['Content-Type'] = 'application/json';
    }
    this.dio.interceptors.add(
          InterceptorsWrapper(onRequest: _attachAuth, onError: _onError),
        );
  }

  final Dio dio;
  final Dio _bare;
  final TokenStore store;
  final Future<void> Function()? onSessionExpired;

  static const _retriedFlag = '__dc_retried__';

  Future<void> _attachAuth(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await store.accessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(DioException error, ErrorInterceptorHandler handler) async {
    final isAuthError = error.response?.statusCode == 401;
    final alreadyRetried = error.requestOptions.extra[_retriedFlag] == true;
    if (!isAuthError || alreadyRetried) {
      return handler.next(error);
    }

    final refreshToken = await store.refreshToken();
    if (refreshToken == null) {
      return handler.next(error);
    }

    try {
      final refreshed = await _bare.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = refreshed.data!;
      await store.save(
        access: data['access_token'] as String,
        refresh: data['refresh_token'] as String,
      );

      final retryOptions = error.requestOptions
        ..extra[_retriedFlag] = true
        ..headers['Authorization'] = 'Bearer ${data['access_token']}';
      final response = await _bare.fetch<dynamic>(retryOptions);
      return handler.resolve(response);
    } on DioException {
      await store.clear();
      await onSessionExpired?.call();
      return handler.next(error);
    }
  }
}
