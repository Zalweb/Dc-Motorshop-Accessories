// ─────────────────────────────────────────────────────────────────────────────
// Web-safe model: InventoryTransaction (no isar annotations, no part directive)
// ─────────────────────────────────────────────────────────────────────────────
import '../../core/utils/uuid.dart';

/// An immutable stock movement record — web-safe mirror of native [InventoryTransaction].
class InventoryTransaction {
  InventoryTransaction({
    String? uid,
    this.productVariantUid = '',
    this.productName = '',
    this.transactionType = 'STOCK_ADJUSTMENT',
    this.quantity = 0,
    this.unitCost,
    this.referenceType,
    this.referenceId,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDirty = true,
  })  : uid = uid ?? uuidV7(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Surrogate for Isar integer id. Unused on web.
  int id = 0;

  String uid;
  String productVariantUid;
  String productName;
  String transactionType;
  int quantity;
  double? unitCost;
  String? referenceType;
  String? referenceId;
  String? notes;
  DateTime createdAt;
  DateTime updatedAt;
  bool isDirty;

  factory InventoryTransaction.fromJson(Map<String, dynamic> j) =>
      InventoryTransaction(
        uid: j['id'] as String? ?? j['uid'] as String? ?? uuidV7(),
        productVariantUid: j['product_variant_id'] as String? ??
            j['product_variant_uid'] as String? ??
            j['product_id'] as String? ??
            '',
        productName: j['product_name'] as String? ?? '',
        transactionType: j['transaction_type'] as String? ?? 'STOCK_ADJUSTMENT',
        quantity: (j['quantity'] as num?)?.toInt() ?? 0,
        unitCost: (j['unit_cost'] as num?)?.toDouble(),
        referenceType: j['reference_type'] as String?,
        referenceId: j['reference_id'] as String?,
        notes: j['notes'] as String?,
        createdAt: j['created_at'] != null
            ? DateTime.parse(j['created_at'] as String)
            : DateTime.now(),
        updatedAt: j['updated_at'] != null
            ? DateTime.parse(j['updated_at'] as String)
            : DateTime.now(),
        isDirty: false,
      );

  Map<String, dynamic> toJson() => {
        'id': uid,
        'product_variant_id': productVariantUid,
        'product_variant_uid': productVariantUid,
        'product_name': productName,
        'transaction_type': transactionType,
        'quantity': quantity,
        if (unitCost != null) 'unit_cost': unitCost,
        if (referenceType != null) 'reference_type': referenceType,
        if (referenceId != null) 'reference_id': referenceId,
        if (notes != null) 'notes': notes,
        'updated_at': updatedAt.toIso8601String(),
      };
}
