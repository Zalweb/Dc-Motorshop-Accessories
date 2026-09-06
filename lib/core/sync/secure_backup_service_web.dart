import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Web cloud-only backup. Local export/import is a no-op here, but the
/// crypto helpers are reproduced (pure Dart, web-safe) so the import/export
/// screen's encrypt/decrypt UI compiles and behaves identically.
final secureBackupServiceProvider = Provider<SecureBackupService>(
  (ref) => SecureBackupService(),
);

class SecureBackupService {
  Future<String> exportDatabaseToJson() async => '';
  Future<void> importDatabaseFromJson(String jsonString) async {}

  // ─── Cryptography Core (shared with native — pure Dart, web-safe) ─────────

  static Uint8List _crypt(Uint8List input, Uint8List key, Uint8List nonce) {
    final output = Uint8List(input.length);
    final count = (input.length / 32).ceil();
    final block = Uint8List(nonce.length + 8);
    block.setRange(0, nonce.length, nonce);
    for (int i = 0; i < count; i++) {
      for (int b = 0; b < 8; b++) {
        block[nonce.length + b] = (i >> (b * 8)) & 0xff;
      }
      final hmac = Hmac(sha256, key);
      final digest = hmac.convert(block).bytes;
      final start = i * 32;
      final end = min(start + 32, input.length);
      for (int j = start; j < end; j++) {
        output[j] = input[j] ^ digest[j - start];
      }
    }
    return output;
  }

  /// Derives a key and an HMAC key from password and salt.
  /// Uses HMAC-SHA256 stretching (default 10,000 iterations).
  static (Uint8List key, Uint8List macKey) _deriveKeys(
    String password,
    Uint8List salt, {
    int iterations = 10000,
  }) {
    final passwordBytes = utf8.encode(password);
    var hash = Uint8List.fromList(passwordBytes);
    final hmac = Hmac(sha256, salt);
    for (int i = 0; i < iterations; i++) {
      hash = Uint8List.fromList(hmac.convert(hash).bytes);
    }
    final keyBytes = Hmac(sha256, hash).convert(utf8.encode('encryption_key')).bytes;
    final macKeyBytes = Hmac(sha256, hash).convert(utf8.encode('mac_key')).bytes;
    return (Uint8List.fromList(keyBytes), Uint8List.fromList(macKeyBytes));
  }

  static Uint8List _randomBytes(int length) {
    final rnd = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = rnd.nextInt(256);
    }
    return bytes;
  }

  static Uint8List encryptPayload(String plaintext, String password) {
    final salt = _randomBytes(16);
    final nonce = _randomBytes(16);
    final (key, macKey) = _deriveKeys(password, salt, iterations: 10000);
    final plaintextBytes = utf8.encode(plaintext);
    final ciphertext = _crypt(Uint8List.fromList(plaintextBytes), key, nonce);

    final header = Uint8List(32);
    header.setRange(0, 16, salt);
    header.setRange(16, 32, nonce);
    final payloadToMac = Uint8List(header.length + ciphertext.length);
    payloadToMac.setRange(0, header.length, header);
    payloadToMac.setRange(header.length, payloadToMac.length, ciphertext);
    final macDigest = Hmac(sha256, macKey).convert(payloadToMac).bytes;

    final finalPayload = Uint8List(64 + ciphertext.length);
    finalPayload.setRange(0, 16, salt);
    finalPayload.setRange(16, 32, nonce);
    finalPayload.setRange(32, 64, macDigest);
    finalPayload.setRange(64, finalPayload.length, ciphertext);
    return finalPayload;
  }

  /// Constant-time comparison between two byte sequences to prevent timing attacks.
  static bool _constantTimeEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// Decrypts [payload] using [password].
  /// Supports both standard 10,000 iteration backups and legacy 500 iteration backups.
  /// Throws [FormatException] on invalid password or corrupted data.
  static String decryptPayload(Uint8List payload, String password) {
    if (payload.length < 64) {
      throw const FormatException('Invalid backup file');
    }
    final salt = payload.sublist(0, 16);
    final nonce = payload.sublist(16, 32);
    final mac = payload.sublist(32, 64);
    final ciphertext = payload.sublist(64);

    final payloadToMac = Uint8List(32 + ciphertext.length);
    payloadToMac.setRange(0, 16, salt);
    payloadToMac.setRange(16, 32, nonce);
    payloadToMac.setRange(32, payloadToMac.length, ciphertext);

    // Try modern 10,000 iterations first, then fallback to legacy 500 iterations
    Uint8List? validKey;
    for (final iters in const [10000, 500]) {
      final (key, macKey) = _deriveKeys(password, salt, iterations: iters);
      final calculatedMac = Hmac(sha256, macKey).convert(payloadToMac).bytes;
      if (_constantTimeEqual(mac, calculatedMac)) {
        validKey = key;
        break;
      }
    }

    if (validKey == null) {
      throw const FormatException('Incorrect password or corrupted file');
    }
    final decryptedBytes = _crypt(ciphertext, validKey, nonce);
    return utf8.decode(decryptedBytes);
  }
}
