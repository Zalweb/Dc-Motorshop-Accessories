import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';
import 'supabase_service.dart';

/// Handles product image uploads to Supabase Storage.
///
/// Replaces [ProductImageApi] (Dio-based). Images are stored in the
/// [kProductImagesBucket] bucket under a path keyed by the product UUID
/// so the same product can be updated without orphaning old files.
class SupabaseStorageService {
  SupabaseClient get _client => SupabaseService.client;

  /// Uploads [localPath] to Supabase Storage and returns the public URL.
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
      final file = File(localPath);
      if (!file.existsSync()) return null;

      final extension = localPath.split('.').last.toLowerCase();
      final storagePath = 'products/$productUid.$extension';

      await _client.storage.from(kProductImagesBucket).upload(
            storagePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      // Signed URL valid for 1 year (365 days).
      final signedUrl = await _client.storage
          .from(kProductImagesBucket)
          .createSignedUrl(storagePath, 60 * 60 * 24 * 365);

      return signedUrl;
    } catch (_) {
      return null;
    }
  }

  /// Uploads a shop logo to Supabase Storage and returns the public URL.
  Future<String?> uploadLogoImage({
    required String businessUid,
    required String localPath,
  }) async {
    try {
      final file = File(localPath);
      if (!file.existsSync()) return null;

      final extension = localPath.split('.').last.toLowerCase();
      final storagePath = 'logos/$businessUid.$extension';

      await _client.storage.from(kProductImagesBucket).upload(
            storagePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      // Signed URL valid for 1 year (365 days).
      final signedUrl = await _client.storage
          .from(kProductImagesBucket)
          .createSignedUrl(storagePath, 60 * 60 * 24 * 365);

      return signedUrl;
    } catch (_) {
      return null;
    }
  }

  /// Refreshes a signed URL for an existing product image.
  Future<String?> refreshSignedUrl(String productUid, String extension) async {
    try {
      final storagePath = 'products/$productUid.$extension';
      return await _client.storage
          .from(kProductImagesBucket)
          .createSignedUrl(storagePath, 60 * 60 * 24 * 365);
    } catch (_) {
      return null;
    }
  }
}
