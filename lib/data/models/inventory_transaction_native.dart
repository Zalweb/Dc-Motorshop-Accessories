import 'package:isar_community/isar.dart';

import '../../core/utils/uuid.dart';

part 'inventory_transaction_native.g.dart';

/// An immutable record of stock movement (e.g. sale, purchase, adjustment).
@collection
class InventoryTransaction {
  Id id = Isar.autoIncrement;

  /// Server-aligned UUID v7
  @Index(unique: true)
  String uid = uuidV7();

  /// Server-aligned Product Variant UUID
  @Index()
  late String productVariantUid;

  /// Human-readable product name + variant name snapshot
  String productName = '';

  /// Transaction type: INITIAL_STOCK, PURCHASE, SALE, SALE_RETURN,
  /// PURCHASE_RETURN, STOCK_ADJUSTMENT, DAMAGE, LOSS
  @Index()
  late String transactionType;

  /// Quantity moved (signed: + for addition, - for reduction)
  int quantity = 0;

  /// Unit cost at the time of transaction
  double? unitCost;

  /// Reference type: 'sale', 'purchase', 'manual', etc.
  String? referenceType;

  /// Reference UUID (e.g. sale.uid)
  String? referenceId;

  String? notes;

  @Index()
  DateTime createdAt = DateTime.now();

  // Sync metadata
  DateTime updatedAt = DateTime.now();
  bool isDirty = true;
}
