import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../providers.dart';
import '../../data/models/business_settings.dart';
import '../../data/models/category.dart';
import '../../data/models/expense.dart';
import '../../data/models/product.dart';
import '../../data/models/sale.dart';
import '../../data/models/user.dart';

final secureBackupServiceProvider = Provider<SecureBackupService>((ref) {
  return SecureBackupService(ref.watch(isarProvider));
});

class SecureBackupService {
  SecureBackupService(this._isar);

  final Isar _isar;

  // ─── Cryptography Core ──────────────────────────────────────────────────────

  /// Simple and cryptographically secure SHA-256 CTR stream cipher.
  /// Encrypts/decrypts [input] using [key] and [nonce].
  static Uint8List _crypt(Uint8List input, Uint8List key, Uint8List nonce) {
    final output = Uint8List(input.length);
    final count = (input.length / 32).ceil();
    final block = Uint8List(nonce.length + 8);
    block.setRange(0, nonce.length, nonce);

    for (int i = 0; i < count; i++) {
      // Set the 64-bit counter at the end of the block
      for (int b = 0; b < 8; b++) {
        block[nonce.length + b] = (i >> (b * 8)) & 0xff;
      }

      // Hash key + block to get 32 bytes of keystream
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
  /// Uses 500 iterations of HMAC-SHA256 stretching.
  static (Uint8List key, Uint8List macKey) _deriveKeys(
    String password,
    Uint8List salt,
  ) {
    final passwordBytes = utf8.encode(password);
    var hash = Uint8List.fromList(passwordBytes);
    final hmac = Hmac(sha256, salt);

    for (int i = 0; i < 500; i++) {
      hash = Uint8List.fromList(hmac.convert(hash).bytes);
    }

    final keyBytes =
        Hmac(sha256, hash).convert(utf8.encode('encryption_key')).bytes;
    final macKeyBytes = Hmac(sha256, hash).convert(utf8.encode('mac_key')).bytes;

    return (
      Uint8List.fromList(keyBytes),
      Uint8List.fromList(macKeyBytes),
    );
  }

  /// Generates cryptographically secure random bytes.
  static Uint8List _randomBytes(int length) {
    final rnd = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = rnd.nextInt(256);
    }
    return bytes;
  }

  /// Encrypts plain text string [plaintext] using [password].
  /// Returns the combined payload: salt(16B) + nonce(16B) + HMAC(32B) + ciphertext.
  static Uint8List encryptPayload(String plaintext, String password) {
    final salt = _randomBytes(16);
    final nonce = _randomBytes(16);
    final (key, macKey) = _deriveKeys(password, salt);

    final plaintextBytes = utf8.encode(plaintext);
    final ciphertext = _crypt(Uint8List.fromList(plaintextBytes), key, nonce);

    // Header prefix to MAC: salt + nonce
    final header = Uint8List(32);
    header.setRange(0, 16, salt);
    header.setRange(16, 32, nonce);

    // Compute MAC over header + ciphertext
    final payloadToMac = Uint8List(header.length + ciphertext.length);
    payloadToMac.setRange(0, header.length, header);
    payloadToMac.setRange(header.length, payloadToMac.length, ciphertext);

    final macDigest = Hmac(sha256, macKey).convert(payloadToMac).bytes;

    // Combine: salt(16) + nonce(16) + MAC(32) + ciphertext
    final finalPayload = Uint8List(64 + ciphertext.length);
    finalPayload.setRange(0, 16, salt);
    finalPayload.setRange(16, 32, nonce);
    finalPayload.setRange(32, 64, macDigest);
    finalPayload.setRange(64, finalPayload.length, ciphertext);

    return finalPayload;
  }

  /// Decrypts [payload] using [password].
  /// Throws [FormatException] on invalid password or corrupted data.
  static String decryptPayload(Uint8List payload, String password) {
    if (payload.length < 64) {
      throw const FormatException('Invalid backup file');
    }

    final salt = payload.sublist(0, 16);
    final nonce = payload.sublist(16, 32);
    final mac = payload.sublist(32, 64);
    final ciphertext = payload.sublist(64);

    final (key, macKey) = _deriveKeys(password, salt);

    // Re-verify MAC
    final payloadToMac = Uint8List(32 + ciphertext.length);
    payloadToMac.setRange(0, 16, salt);
    payloadToMac.setRange(16, 32, nonce);
    payloadToMac.setRange(32, payloadToMac.length, ciphertext);

    final calculatedMac = Hmac(sha256, macKey).convert(payloadToMac).bytes;

    // Constant-time-like comparison
    bool matches = true;
    for (int i = 0; i < 32; i++) {
      if (mac[i] != calculatedMac[i]) {
        matches = false;
      }
    }

    if (!matches) {
      throw const FormatException('Incorrect password or corrupted file');
    }

    final decryptedBytes = _crypt(ciphertext, key, nonce);
    return utf8.decode(decryptedBytes);
  }

  // ─── Database Export & Import ──────────────────────────────────────────────

  /// Exports all Isar collections into a single JSON string.
  Future<String> exportDatabaseToJson() async {
    final users = await _isar.users.where().findAll();
    final businessSettings = await _isar.businessSettings.where().findAll();
    final categories = await _isar.categorys.where().findAll();
    final products = await _isar.products.where().findAll();
    final expenses = await _isar.expenses.where().findAll();
    final sales = await _isar.sales.where().findAll();

    final Map<String, dynamic> backupData = {
      'version': 1,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'tables': {
        'users': users.map(_userToJson).toList(),
        'business_settings': businessSettings.map(_settingsToJson).toList(),
        'categories': categories.map(_categoryToJson).toList(),
        'products': products.map(_productToJson).toList(),
        'expenses': expenses.map(_expenseToJson).toList(),
        'sales': sales.map(_saleToJson).toList(),
      }
    };

    return jsonEncode(backupData);
  }

  /// Restores Isar collections from decrypted JSON.
  /// This deletes all existing rows inside a transaction before insertion.
  Future<void> importDatabaseFromJson(String jsonString) async {
    final Map<String, dynamic> parsed = jsonDecode(jsonString) as Map<String, dynamic>;
    if (parsed['version'] != 1) {
      throw FormatException('Unsupported backup version: ${parsed['version']}');
    }

    final tables = parsed['tables'] as Map<String, dynamic>;

    final usersList = (tables['users'] as List? ?? [])
        .map((x) => _userFromJson(x as Map<String, dynamic>))
        .toList();
    final settingsList = (tables['business_settings'] as List? ?? [])
        .map((x) => _settingsFromJson(x as Map<String, dynamic>))
        .toList();
    final categoriesList = (tables['categories'] as List? ?? [])
        .map((x) => _categoryFromJson(x as Map<String, dynamic>))
        .toList();
    final productsList = (tables['products'] as List? ?? [])
        .map((x) => _productFromJson(x as Map<String, dynamic>))
        .toList();
    final expensesList = (tables['expenses'] as List? ?? [])
        .map((x) => _expenseFromJson(x as Map<String, dynamic>))
        .toList();
    final salesList = (tables['sales'] as List? ?? [])
        .map((x) => _saleFromJson(x as Map<String, dynamic>))
        .toList();

    await _isar.writeTxn(() async {
      // Clear existing records
      await _isar.users.clear();
      await _isar.businessSettings.clear();
      await _isar.categorys.clear();
      await _isar.products.clear();
      await _isar.expenses.clear();
      await _isar.sales.clear();

      // Insert new records
      if (usersList.isNotEmpty) await _isar.users.putAll(usersList);
      if (settingsList.isNotEmpty) await _isar.businessSettings.putAll(settingsList);
      if (categoriesList.isNotEmpty) await _isar.categorys.putAll(categoriesList);
      if (productsList.isNotEmpty) await _isar.products.putAll(productsList);
      if (expensesList.isNotEmpty) await _isar.expenses.putAll(expensesList);
      if (salesList.isNotEmpty) await _isar.sales.putAll(salesList);
    });
  }

  // ─── Serialization Helpers ─────────────────────────────────────────────────

  Map<String, dynamic> _userToJson(User u) => {
        'uid': u.uid,
        'businessUid': u.businessUid,
        'username': u.username,
        'email': u.email,
        'passwordHash': u.passwordHash,
        'passwordSalt': u.passwordSalt,
        'fullName': u.fullName,
        'phone': u.phone,
        'onboardingComplete': u.onboardingComplete,
        'createdAt': u.createdAt.toIso8601String(),
      };

  User _userFromJson(Map<String, dynamic> map) => User()
    ..uid = map['uid'] as String
    ..businessUid = map['businessUid'] as String?
    ..username = map['username'] as String
    ..email = map['email'] as String
    ..passwordHash = map['passwordHash'] as String
    ..passwordSalt = map['passwordSalt'] as String
    ..fullName = map['fullName'] as String?
    ..phone = map['phone'] as String?
    ..onboardingComplete = map['onboardingComplete'] as bool
    ..createdAt = DateTime.parse(map['createdAt'] as String);

  Map<String, dynamic> _settingsToJson(BusinessSettings s) => {
        'uid': s.uid,
        'businessName': s.businessName,
        'businessType': s.businessType,
        'logoPath': s.logoPath,
        'address': s.address,
        'phone': s.phone,
        'email': s.email,
        'timezone': s.timezone,
        'currency': s.currency,
        'receiptQrLink': s.receiptQrLink,
        'categories': s.categories,
        'workflowStages': s.workflowStages,
        'themeColor': s.themeColor,
        'completedChecklistItems': s.completedChecklistItems,
        'allowSellWhenOutOfStock': s.allowSellWhenOutOfStock,
        'trackPartialChange': s.trackPartialChange,
        'includeUnpaidInReports': s.includeUnpaidInReports,
        'updatedAt': s.updatedAt.toIso8601String(),
        'isDirty': s.isDirty,
      };

  BusinessSettings _settingsFromJson(Map<String, dynamic> map) =>
      BusinessSettings()
        ..uid = map['uid'] as String
        ..businessName = map['businessName'] as String
        ..businessType = map['businessType'] as String
        ..logoPath = map['logoPath'] as String?
        ..address = map['address'] as String?
        ..phone = map['phone'] as String?
        ..email = map['email'] as String?
        ..timezone = map['timezone'] as String
        ..currency = map['currency'] as String
        ..receiptQrLink = map['receiptQrLink'] as String?
        ..categories = List<String>.from(map['categories'] as List)
        ..workflowStages = List<String>.from(map['workflowStages'] as List)
        ..themeColor = map['themeColor'] as String
        ..completedChecklistItems =
            List<String>.from(map['completedChecklistItems'] as List)
        ..allowSellWhenOutOfStock = map['allowSellWhenOutOfStock'] as bool
        ..trackPartialChange = map['trackPartialChange'] as bool
        ..includeUnpaidInReports = map['includeUnpaidInReports'] as bool
        ..updatedAt = DateTime.parse(map['updatedAt'] as String)
        ..isDirty = map['isDirty'] as bool;

  Map<String, dynamic> _categoryToJson(Category c) => {
        'uid': c.uid,
        'name': c.name,
        'isService': c.isService,
        'createdAt': c.createdAt.toIso8601String(),
        'updatedAt': c.updatedAt.toIso8601String(),
        'isDirty': c.isDirty,
      };

  Category _categoryFromJson(Map<String, dynamic> map) => Category()
    ..uid = map['uid'] as String
    ..name = map['name'] as String
    ..isService = map['isService'] as bool
    ..createdAt = DateTime.parse(map['createdAt'] as String)
    ..updatedAt = DateTime.parse(map['updatedAt'] as String)
    ..isDirty = map['isDirty'] as bool;

  Map<String, dynamic> _productToJson(Product p) => {
        'uid': p.uid,
        'name': p.name,
        'barcode': p.barcode,
        'category': p.category,
        'description': p.description,
        'partNumber': p.partNumber,
        'brand': p.brand,
        'unit': p.unit,
        'isService': p.isService,
        'costPrice': p.costPrice,
        'sellingPrice': p.sellingPrice,
        'stockQty': p.stockQty,
        'imagePath': p.imagePath,
        'imageUrl': p.imageUrl,
        'createdAt': p.createdAt.toIso8601String(),
        'updatedAt': p.updatedAt.toIso8601String(),
        'isDirty': p.isDirty,
      };

  Product _productFromJson(Map<String, dynamic> map) => Product()
    ..uid = map['uid'] as String
    ..name = map['name'] as String
    ..barcode = map['barcode'] as String?
    ..category = map['category'] as String?
    ..description = map['description'] as String?
    ..partNumber = map['partNumber'] as String?
    ..brand = map['brand'] as String?
    ..unit = map['unit'] as String
    ..isService = map['isService'] as bool
    ..costPrice = double.parse(map['costPrice'].toString())
    ..sellingPrice = double.parse(map['sellingPrice'].toString())
    ..stockQty = map['stockQty'] as int
    ..imagePath = map['imagePath'] as String?
    ..imageUrl = map['imageUrl'] as String?
    ..createdAt = DateTime.parse(map['createdAt'] as String)
    ..updatedAt = DateTime.parse(map['updatedAt'] as String)
    ..isDirty = map['isDirty'] as bool;

  Map<String, dynamic> _expenseToJson(Expense e) => {
        'uid': e.uid,
        'label': e.label,
        'amount': e.amount,
        'note': e.note,
        'type': e.type,
        'category': e.category,
        'frequency': e.frequency,
        'endDate': e.endDate?.toIso8601String(),
        'includeInCalculations': e.includeInCalculations,
        'createdAt': e.createdAt.toIso8601String(),
        'updatedAt': e.updatedAt.toIso8601String(),
        'isDirty': e.isDirty,
      };

  Expense _expenseFromJson(Map<String, dynamic> map) => Expense()
    ..uid = map['uid'] as String
    ..label = map['label'] as String
    ..amount = double.parse(map['amount'].toString())
    ..note = map['note'] as String?
    ..type = map['type'] as String
    ..category = map['category'] as String?
    ..frequency = map['frequency'] as String?
    ..endDate = map['endDate'] != null ? DateTime.parse(map['endDate'] as String) : null
    ..includeInCalculations = map['includeInCalculations'] as bool
    ..createdAt = DateTime.parse(map['createdAt'] as String)
    ..updatedAt = DateTime.parse(map['updatedAt'] as String)
    ..isDirty = map['isDirty'] as bool;

  Map<String, dynamic> _saleToJson(Sale s) => {
        'uid': s.uid,
        'saleNumber': s.saleNumber,
        'customerName': s.customerName,
        'subtotal': s.subtotal,
        'discount': s.discount,
        'total': s.total,
        'status': s.status,
        'paymentMethod': s.paymentMethod,
        'amountReceived': s.amountReceived,
        'notes': s.notes,
        'createdAt': s.createdAt.toIso8601String(),
        'updatedAt': s.updatedAt.toIso8601String(),
        'isDirty': s.isDirty,
        'items': s.items
            .map((it) => {
                  'name': it.name,
                  'quantity': it.quantity,
                  'unitPrice': it.unitPrice,
                  'unitCost': it.unitCost,
                  'lineTotal': it.lineTotal,
                  'productId': it.productId,
                  'productUid': it.productUid,
                })
            .toList(),
      };

  Sale _saleFromJson(Map<String, dynamic> map) => Sale()
    ..uid = map['uid'] as String
    ..saleNumber = map['saleNumber'] as String
    ..customerName = map['customerName'] as String?
    ..subtotal = double.parse(map['subtotal'].toString())
    ..discount = double.parse(map['discount'].toString())
    ..total = double.parse(map['total'].toString())
    ..status = map['status'] as String
    ..paymentMethod = map['paymentMethod'] as String
    ..amountReceived = double.parse(map['amountReceived'].toString())
    ..notes = map['notes'] as String?
    ..createdAt = DateTime.parse(map['createdAt'] as String)
    ..updatedAt = DateTime.parse(map['updatedAt'] as String)
    ..isDirty = map['isDirty'] as bool
    ..items = (map['items'] as List).map((itMap) {
      final it = itMap as Map<String, dynamic>;
      return SaleItem()
        ..name = it['name'] as String
        ..quantity = it['quantity'] as int
        ..unitPrice = double.parse(it['unitPrice'].toString())
        ..unitCost = double.parse(it['unitCost'].toString())
        ..lineTotal = double.parse(it['lineTotal'].toString())
        ..productId = it['productId'] as int?
        ..productUid = it['productUid'] as String?;
    }).toList();
}
