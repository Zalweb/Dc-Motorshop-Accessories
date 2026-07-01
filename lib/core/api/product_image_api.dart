import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_exception.dart';

/// Uploads a product image. The product must already exist server-side (sync it first);
/// the backend validates type/size, stores it under a random key, and returns a signed URL.
class ProductImageApi {
  ProductImageApi(this._client);

  final ApiClient _client;
  Dio get _dio => _client.dio;

  Future<String> upload(String productUid, String filePath) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final res = await _dio.post<Map<String, dynamic>>(
        '/products/$productUid/image',
        data: form,
      );
      return res.data!['url'] as String;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
