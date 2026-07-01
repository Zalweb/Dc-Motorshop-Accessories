import 'dart:math';

/// Generates a UUID v7 (time-ordered) string — the same scheme the FastAPI backend uses,
/// so a record's id lines up across Isar and Postgres for offline-first sync.
///
/// Layout (RFC 9562): 48-bit Unix-ms timestamp, 4-bit version, 12 random bits, 2-bit
/// variant, 62 random bits.
String uuidV7() {
  final now = DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFFFFFF; // 48 bits
  final rng = Random.secure();

  final bytes = List<int>.filled(16, 0);
  // 48-bit timestamp, big-endian, into bytes 0..5.
  bytes[0] = (now >> 40) & 0xFF;
  bytes[1] = (now >> 32) & 0xFF;
  bytes[2] = (now >> 24) & 0xFF;
  bytes[3] = (now >> 16) & 0xFF;
  bytes[4] = (now >> 8) & 0xFF;
  bytes[5] = now & 0xFF;
  for (var i = 6; i < 16; i++) {
    bytes[i] = rng.nextInt(256);
  }
  bytes[6] = 0x70 | (bytes[6] & 0x0F); // version 7
  bytes[8] = 0x80 | (bytes[8] & 0x3F); // variant

  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}'
      '-${hex.substring(16, 20)}-${hex.substring(20)}';
}
