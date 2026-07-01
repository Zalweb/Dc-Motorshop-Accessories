import 'package:isar_community/isar.dart';

import '../../core/utils/uuid.dart';

part 'sale.g.dart';

/// A completed sale (receipt). Line items are embedded so a sale is one record.
@collection
class Sale {
  Id id = Isar.autoIncrement;

  /// Server-aligned UUID v7 — the canonical id used by the API and sync.
  @Index(unique: true)
  String uid = uuidV7();

  @Index()
  late String saleNumber;

  String? customerName;

  List<SaleItem> items = [];

  double subtotal = 0;
  double discount = 0;
  double total = 0;

  /// Payment status: 'paid', 'partial', or 'unpaid'.
  String status = 'paid';

  /// Payment method: 'cash', 'gcash', 'bank', or 'card'.
  String paymentMethod = 'cash';

  /// Cash tendered by the customer (relevant for cash payments).
  double amountReceived = 0;

  String? notes;

  @Index()
  DateTime createdAt = DateTime.now();

  // Sync metadata. Sales are append-only server-side; pushed via POST /sales.
  DateTime updatedAt = DateTime.now();
  bool isDirty = true;
}

/// A single line on a sale. Cost is snapshotted for accurate COGS later.
@embedded
class SaleItem {
  String name = '';
  int quantity = 1;
  double unitPrice = 0;
  double unitCost = 0;
  double lineTotal = 0;

  /// Local Isar id of the product (for stock decrement).
  int? productId;

  /// Server-aligned product UUID (for checkout push).
  String? productUid;
}
