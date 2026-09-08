import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';
import 'supabase_service.dart';
import '../utils/security_sanitizer.dart';

/// Handles product image uploads to Supabase Storage.
///
/// Replaces [ProductImageApi] (Dio-based). Images are stored in the
/// [kProductImagesBucket] bucket under a path keyed by the product UUID
/// so the same product can be updated without orphaning old files.
class SupabaseStorageService {
  SupabaseClient get _client => SupabaseService.client;

  String get _authUid {
    final uid = _client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) {
      throw StateError('User must be logged in to access Supabase Storage.');
    }
    return uid;
  }

  Future<Uint8List> _compressImage(Uint8List bytes) async {
    final compressed = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 1024,
      minHeight: 1024,
      quality: 85,
      format: CompressFormat.jpeg,
    );
    return compressed;
  }

  /// Uploads [localPath] to Supabase Storage and returns the public URL.
  /// Supports local file paths as well as base64 data URLs (`data:...`).
  ///
  /// Uses an upsert so re-uploading an image for the same product simply
  /// replaces the old file without creating duplicates.
  ///
  /// Returns null if the upload fails (best-effort; retry on next sync).
  Future<String?> uploadProductImage({
    required String productUid,
    required String localPath,
  }) async {
    try {
      if (!isSafeIdentifier(productUid)) return null;
      final authUid = _authUid;

      if (localPath.startsWith('data:')) {
        final comma = localPath.indexOf(',');
        final b64 = comma != -1 ? localPath.substring(comma + 1) : localPath;
        final originalBytes = Uint8List.fromList(base64Decode(b64));
        final bytes = kIsWeb ? originalBytes : await _compressImage(originalBytes);
        String extension = 'jpg';
        if (localPath.startsWith('data:image/png')) {
          extension = 'png';
        } else if (localPath.startsWith('data:image/webp')) {
          extension = 'webp';
        }
        final storagePath = '$authUid/products/$productUid.$extension';

        await _client.storage.from(kProductImagesBucket).uploadBinary(
              storagePath,
              bytes,
              fileOptions: FileOptions(upsert: true, contentType: 'image/$extension'),
            );

        final signedUrl = await _client.storage
            .from(kProductImagesBucket)
            .createSignedUrl(storagePath, 60 * 60 * 24 * 365); // 1-year expiry on mobile (offline-first)

        return signedUrl;
      }

      final file = File(localPath);
      if (!file.existsSync()) return null;

      final rawExtension = localPath.split('.').last.toLowerCase();
      final extension = isAllowedImageExtension(rawExtension) ? rawExtension : 'jpg';
      final storagePath = '$authUid/products/$productUid.$extension';

      final originalBytes = await file.readAsBytes();
      final bytes = kIsWeb ? originalBytes : await _compressImage(originalBytes);

      await _client.storage.from(kProductImagesBucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: 'image/$extension'),
          );

      // Signed URL valid for 1 year on mobile (offline-first — URLs cached locally).
      final signedUrl = await _client.storage
          .from(kProductImagesBucket)
          .createSignedUrl(storagePath, 60 * 60 * 24 * 365); // 1-year expiry on mobile (offline-first)

      return signedUrl;
    } catch (e) {
      debugPrint('Image upload failed: $e');
      throw Exception('Image upload failed: $e');
    }
  }

  /// Uploads a shop logo to Supabase Storage and returns the public URL.
  /// Supports local file paths as well as base64 data URLs (`data:...`).
  Future<String?> uploadLogoImage({
    required String businessUid,
    required String localPath,
  }) async {
    try {
      if (!isSafeIdentifier(businessUid)) return null;
      final authUid = _authUid;

      if (localPath.startsWith('data:')) {
        final comma = localPath.indexOf(',');
        final b64 = comma != -1 ? localPath.substring(comma + 1) : localPath;
        final originalBytes = Uint8List.fromList(base64Decode(b64));
        final bytes = kIsWeb ? originalBytes : await _compressImage(originalBytes);
        String extension = 'png';
        if (localPath.startsWith('data:image/jpeg') || localPath.startsWith('data:image/jpg')) {
          extension = 'jpg';
        } else if (localPath.startsWith('data:image/webp')) {
          extension = 'webp';
        }
        final storagePath = '$authUid/logos/$businessUid.$extension';

        await _client.storage.from(kProductImagesBucket).uploadBinary(
              storagePath,
              bytes,
              fileOptions: FileOptions(upsert: true, contentType: 'image/$extension'),
            );

        final signedUrl = await _client.storage
            .from(kProductImagesBucket)
            .createSignedUrl(storagePath, 60 * 60 * 24 * 365); // 1-year expiry on mobile (offline-first)

        return signedUrl;
      }

      final file = File(localPath);
      if (!file.existsSync()) return null;

      final rawExtension = localPath.split('.').last.toLowerCase();
      final extension = isAllowedImageExtension(rawExtension) ? rawExtension : 'jpg';
      final storagePath = '$authUid/logos/$businessUid.$extension';

      final originalBytes = await file.readAsBytes();
      final bytes = kIsWeb ? originalBytes : await _compressImage(originalBytes);

      await _client.storage.from(kProductImagesBucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: 'image/$extension'),
          );

      // Signed URL valid for 1 year on mobile (offline-first — URLs cached locally).
      final signedUrl = await _client.storage
          .from(kProductImagesBucket)
          .createSignedUrl(storagePath, 60 * 60 * 24 * 365); // 1-year expiry on mobile (offline-first)

      return signedUrl;
    } catch (e) {
      debugPrint('Image upload failed: $e');
      throw Exception('Image upload failed: $e');
    }
  }

  /// Refreshes a signed URL for an existing product image.
  Future<String?> refreshSignedUrl(String productUid, String extension) async {
    try {
      final authUid = _authUid;
      final storagePath = '$authUid/products/$productUid.$extension';
      return await _client.storage
          .from(kProductImagesBucket)
          .createSignedUrl(storagePath, 60 * 60 * 24 * 365); // 1-year expiry on mobile (offline-first)
    } catch (e) {
      debugPrint('Refresh signed URL failed: $e');
      return null;
    }
  }
}
