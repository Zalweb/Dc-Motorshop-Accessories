import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_exception.dart';

/// Server view of the authenticated user.
class ApiUser {
  ApiUser({
    required this.id,
    required this.businessId,
    required this.username,
    required this.email,
    required this.role,
    required this.onboardingComplete,
    this.fullName,
    this.phone,
  });

  final String id;
  final String businessId;
  final String username;
  final String email;
  final String role;
  final bool onboardingComplete;
  final String? fullName;
  final String? phone;

  factory ApiUser.fromJson(Map<String, dynamic> json) => ApiUser(
        id: json['id'] as String,
        businessId: json['business_id'] as String,
        username: json['username'] as String,
        email: json['email'] as String,
        role: (json['role'] ?? 'owner') as String,
        onboardingComplete: (json['onboarding_complete'] ?? false) as bool,
        fullName: json['full_name'] as String?,
        phone: json['phone'] as String?,
      );
}

class AuthSession {
  AuthSession({required this.user, required this.accessToken, required this.refreshToken});

  final ApiUser user;
  final String accessToken;
  final String refreshToken;
}

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;
  Dio get _dio => _client.dio;

  Future<AuthSession> register({
    required String businessName,
    required String username,
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/auth/register', data: {
        'business_name': businessName,
        'username': username,
        'email': email,
        'password': password,
        'full_name': ?fullName,
        'phone': ?phone,
      });
      return _session(res.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<AuthSession> login(String username, String password) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      return _session(res.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ApiUser> me() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/auth/me');
      return ApiUser.fromJson(res.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> patchMe({bool? onboardingComplete, String? fullName, String? phone}) async {
    try {
      await _dio.patch<Map<String, dynamic>>('/auth/me', data: {
        'onboarding_complete': ?onboardingComplete,
        'full_name': ?fullName,
        'phone': ?phone,
      });
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post<void>('/auth/logout', data: {'refresh_token': refreshToken});
    } on DioException {
      // Logout is best-effort; the local session is cleared regardless.
    }
  }

  AuthSession _session(Map<String, dynamic> data) {
    final tokens = data['tokens'] as Map<String, dynamic>;
    return AuthSession(
      user: ApiUser.fromJson(data['user'] as Map<String, dynamic>),
      accessToken: tokens['access_token'] as String,
      refreshToken: tokens['refresh_token'] as String,
    );
  }
}
