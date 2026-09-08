import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_config.dart';
import '../supabase/supabase_service.dart';
import '../utils/security_sanitizer.dart';

/// Web-safe storage service. Uploads images from bytes (web image/file
/// pickers produce bytes, not local file paths). The `localPath` params are
/// accepted for API compatibility and can also carry base64 data URLs.
class SupabaseStorageServiceWeb {
  SupabaseClient get _client => SupabaseService.client;

  String get _authUid {
    final uid = _client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) {
      throw StateError('User must be logged in to access Supabase Storage.');
    }
    return uid;
  }

  Future<String?> uploadProductImage({
    required String productUid,
    required String localPath,
    Uint8List? bytes,
  }) async {
    if (!isSafeIdentifier(productUid)) return null;
    final authUid = _authUid;
    String extension = 'jpg';
    Uint8List? uploadBytes = bytes;

    if (uploadBytes == null && localPath.startsWith('data:')) {
      final comma = localPath.indexOf(',');
      final b64 = comma != -1 ? localPath.substring(comma + 1) : localPath;
      try {
        uploadBytes = Uint8List.fromList(base64Decode(b64));
      } catch (e) {
        debugPrint('Failed to decode base64 image: $e');
        return null;
      }
      if (localPath.startsWith('data:image/png')) {
        extension = 'png';
      } else if (localPath.startsWith('data:image/webp')) {
        extension = 'webp';
      }
    }

    return _upload(
      storagePath: '$authUid/products/$productUid.$extension',
      bytes: uploadBytes,
      contentType: 'image/$extension',
    );
  }

  Future<String?> uploadLogoImage({
    required String businessUid,
    required String localPath,
    Uint8List? bytes,
  }) async {
    if (!isSafeIdentifier(businessUid)) return null;
    final authUid = _authUid;
    String extension = 'png';
    Uint8List? uploadBytes = bytes;

    if (uploadBytes == null && localPath.startsWith('data:')) {
      final comma = localPath.indexOf(',');
      final b64 = comma != -1 ? localPath.substring(comma + 1) : localPath;
      try {
        uploadBytes = Uint8List.fromList(base64Decode(b64));
      } catch (e) {
        debugPrint('Failed to decode base64 image: $e');
        return null;
      }
      if (localPath.startsWith('data:image/jpeg') || localPath.startsWith('data:image/jpg')) {
        extension = 'jpg';
      } else if (localPath.startsWith('data:image/webp')) {
        extension = 'webp';
      }
    }

    return _upload(
      storagePath: '$authUid/logos/$businessUid.$extension',
      bytes: uploadBytes,
      contentType: 'image/$extension',
    );
  }

  Future<String?> refreshSignedUrl(String productUid, String extension) async {
    if (!isSafeIdentifier(productUid)) return null;
    final safeExt = isAllowedImageExtension(extension) ? extension : 'jpg';
    final authUid = _authUid;
    return _signedUrl('$authUid/products/$productUid.$safeExt');
  }

  Future<String?> _upload({
    required String storagePath,
    Uint8List? bytes,
    String? contentType,
  }) async {
    try {
      if (bytes == null) return null;
      await _client.storage
          .from(kProductImagesBucket)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          );
      return _signedUrl(storagePath);
    } catch (e) {
      debugPrint('Web image upload failed: $e');
      throw Exception('Image upload failed: $e');
    }
  }

  Future<String?> _signedUrl(String path) async {
    try {
      return await _client.storage
          .from(kProductImagesBucket)
          .createSignedUrl(path, 60 * 60 * 24); // 24-hour expiry on web
    } catch (e) {
      debugPrint('Web signed URL generation failed: $e');
      return null;
    }
  }
}
