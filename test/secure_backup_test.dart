import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:dc_motorcycle_inventory/core/sync/secure_backup_service.dart';

void main() {
  group('SecureBackupService Cryptography Tests', () {
    const testPlaintext = '{"hello": "world", "secret": "motorshop_data_123"}';
    const correctPassword = 'super_secure_password_123';
    const wrongPassword = 'wrong_password_abc';

    test('Encryption and Decryption with correct password succeeds', () {
      // 1. Encrypt
      final encryptedBytes = SecureBackupService.encryptPayload(
        testPlaintext,
        correctPassword,
      );

      expect(encryptedBytes, isNotNull);
      expect(encryptedBytes.length, greaterThan(64)); // salt(16) + nonce(16) + mac(32) + ciphertext

      // 2. Decrypt
      final decryptedText = SecureBackupService.decryptPayload(
        encryptedBytes,
        correctPassword,
      );

      expect(decryptedText, equals(testPlaintext));
    });

    test('Decryption with wrong password throws FormatException', () {
      final encryptedBytes = SecureBackupService.encryptPayload(
        testPlaintext,
        correctPassword,
      );

      expect(
        () => SecureBackupService.decryptPayload(encryptedBytes, wrongPassword),
        throwsA(isA<FormatException>()),
      );
    });

    test('Decryption of tampered ciphertext fails', () {
      final encryptedBytes = SecureBackupService.encryptPayload(
        testPlaintext,
        correctPassword,
      );

      // Tamper with the ciphertext (e.g., change the last byte)
      final tamperedBytes = Uint8List.fromList(encryptedBytes);
      tamperedBytes[tamperedBytes.length - 1] ^= 0xFF;

      expect(
        () => SecureBackupService.decryptPayload(tamperedBytes, correctPassword),
        throwsA(isA<FormatException>()),
      );
    });

    test('Decryption of tampered MAC fails', () {
      final encryptedBytes = SecureBackupService.encryptPayload(
        testPlaintext,
        correctPassword,
      );

      // Tamper with the MAC (bytes 32 to 64)
      final tamperedBytes = Uint8List.fromList(encryptedBytes);
      tamperedBytes[45] ^= 0xFF;

      expect(
        () => SecureBackupService.decryptPayload(tamperedBytes, correctPassword),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
