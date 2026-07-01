import 'package:dc_motorcycle_inventory/core/api/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final request = RequestOptions(path: '/x');

  test('a connection error maps to a network error (drives offline fallback)', () {
    final exception = ApiException.fromDio(
      DioException(requestOptions: request, type: DioExceptionType.connectionError),
    );
    expect(exception.isNetworkError, isTrue);
  });

  test('the backend error envelope is parsed into code and message', () {
    final exception = ApiException.fromDio(
      DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: 409,
          data: {
            'error': {'code': 'already_exists', 'message': 'Account already exists'}
          },
        ),
      ),
    );
    expect(exception.message, 'Account already exists');
  });

  test('a 401 envelope is flagged unauthorized', () {
    final exception = ApiException.fromDio(
      DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: 401,
          data: {
            'error': {'code': 'unauthorized', 'message': 'Authentication required'}
          },
        ),
      ),
    );
    expect(exception.isUnauthorized, isTrue);
  });
}
