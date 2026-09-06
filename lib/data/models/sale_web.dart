// ─────────────────────────────────────────────────────────────────────────────
// Web-safe models: Sale + SaleItem (no isar annotations, no part directive)
// ─────────────────────────────────────────────────────────────────────────────
import '../../core/utils/uuid.dart';

/// A single line on a sale — web-safe mirror of native [SaleItem].
class SaleItem {
  SaleItem({
    this.name = '',
    this.quantity = 1,
    this.unitPrice = 0,
    this.unitCost = 0,
    this.lineTotal = 0,
    this.productId,
    this.productUid,
    this.variantUid,
    this.variantName,
    this.sku,
  });

  String name;
  int quantity;
  double unitPrice;
  double unitCost;
  double lineTotal;

  /// Integer product id — not used on web (always null).
  int? productId;

  String? productUid;
  String? variantUid;
  String? variantName;
  String? sku;

  factory SaleItem.fromJson(Map<String, dynamic> j) => SaleItem(
        name: j['name'] as String? ?? '',
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (j['unit_price'] as num?)?.toDouble() ?? 0,
        unitCost: (j['unit_cost'] as num?)?.toDouble() ?? 0,
        lineTotal: (j['line_total'] as num?)?.toDouble() ?? 0,
        productUid: j['product_id'] as String?,
        variantUid: j['variant_uid'] as String?,
        variantName: j['variant_name'] as String?,
        sku: j['sku'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit_price': unitPrice,
        'unit_cost': unitCost,
        'line_total': lineTotal,
        if (productUid != null) 'product_id': productUid,
        if (variantUid != null) 'variant_uid': variantUid,
        if (variantName != null) 'variant_name': variantName,
        if (sku != null) 'sku': sku,
      };
}

/// A completed sale receipt — web-safe mirror of native [Sale].
class Sale {
  Sale({
    String? uid,
    this.saleNumber = '',
    this.customerName,
    List<SaleItem>? items,
    this.subtotal = 0,
    this.discount = 0,
    this.total = 0,
    this.status = 'paid',
    this.paymentMethod = 'cash',
    this.amountReceived = 0,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDirty = true,
  })  : uid = uid ?? uuidV7(),
        items = items ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Surrogate for Isar integer id. Unused on web.
  int id = 0;

  String uid;
  String saleNumber;
  String? customerName;
  List<SaleItem> items;
  double subtotal;
  double discount;
  double total;
  String status;
  String paymentMethod;
  double amountReceived;
  String? notes;
  DateTime createdAt;
  DateTime updatedAt;
  bool isDirty;

  factory Sale.fromJson(Map<String, dynamic> j) {
    final itemsJson = j['sale_items'] as List<dynamic>? ?? [];
    return Sale(
      uid: j['id'] as String? ?? j['uid'] as String? ?? uuidV7(),
      saleNumber: j['sale_number'] as String? ?? '',
      customerName: j['customer_name'] as String?,
      items: itemsJson
          .map((i) => SaleItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      subtotal: (j['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (j['discount'] as num?)?.toDouble() ?? 0,
      total: (j['total'] as num?)?.toDouble() ?? 0,
      status: j['status'] as String? ?? 'paid',
      paymentMethod: j['payment_method'] as String? ?? 'cash',
      amountReceived: (j['amount_received'] as num?)?.toDouble() ?? 0,
      notes: j['notes'] as String?,
      createdAt: j['created_at'] != null
          ? DateTime.parse(j['created_at'] as String)
          : DateTime.now(),
      updatedAt: j['updated_at'] != null
          ? DateTime.parse(j['updated_at'] as String)
          : DateTime.now(),
      isDirty: false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': uid,
        'sale_number': saleNumber,
        if (customerName != null) 'customer_name': customerName,
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'status': status,
        'payment_method': paymentMethod,
        'amount_received': amountReceived,
        if (notes != null) 'notes': notes,
        'updated_at': updatedAt.toIso8601String(),
      };
}
