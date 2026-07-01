import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/product.dart';
import '../../data/models/sale.dart';

/// Thrown by [CartController.checkout] when a non-service line would push stock
/// below zero and "Allow selling when out of stock" is off. [items] lists the
/// offending product names so the UI can explain what to fix.
class OutOfStockException implements Exception {
  OutOfStockException(this.items);

  final List<String> items;
}

class CartLine {
  CartLine({
    required this.productId,
    required this.productUid,
    required this.name,
    required this.unitPrice,
    required this.unitCost,
    required this.quantity,
    required this.isService,
  });

  final int productId;
  final String productUid;
  final String name;
  final double unitPrice;
  final double unitCost;
  final int quantity;
  final bool isService;

  double get lineTotal => unitPrice * quantity;

  CartLine copyWith({int? quantity}) => CartLine(
        productId: productId,
        productUid: productUid,
        name: name,
        unitPrice: unitPrice,
        unitCost: unitCost,
        quantity: quantity ?? this.quantity,
        isService: isService,
      );
}

class CartController extends Notifier<List<CartLine>> {
  @override
  List<CartLine> build() => [];

  void add(Product product) {
    final index = state.indexWhere((l) => l.productId == product.id);
    if (index >= 0) {
      _setQuantity(index, state[index].quantity + 1);
      return;
    }
    state = [
      ...state,
      CartLine(
        productId: product.id,
        productUid: product.uid,
        name: product.name,
        unitPrice: product.sellingPrice,
        unitCost: product.costPrice,
        quantity: 1,
        isService: product.isService,
      ),
    ];
  }

  void increment(int productId) {
    final index = state.indexWhere((l) => l.productId == productId);
    if (index >= 0) _setQuantity(index, state[index].quantity + 1);
  }

  void decrement(int productId) {
    final index = state.indexWhere((l) => l.productId == productId);
    if (index < 0) return;
    final next = state[index].quantity - 1;
    if (next <= 0) {
      state = [...state]..removeAt(index);
    } else {
      _setQuantity(index, next);
    }
  }

  void removeLine(int productId) {
    state = [...state]..removeWhere((l) => l.productId == productId);
  }

  void clear() => state = [];

  void _setQuantity(int index, int quantity) {
    final updated = [...state];
    updated[index] = updated[index].copyWith(quantity: quantity);
    state = updated;
  }

  double get total => state.fold(0, (sum, l) => sum + l.lineTotal);

  /// Persists the cart as a Sale, decrements stock, and clears the cart.
  Future<Sale> checkout({
    String? customerName,
    String status = 'paid',
    String paymentMethod = 'cash',
    double amountReceived = 0,
    String? notes,
    DateTime? date,
  }) async {
    final saleRepo = ref.read(saleRepositoryProvider);
    final productRepo = ref.read(productRepositoryProvider);
    final settings = await ref.read(settingsRepositoryProvider).getOrCreate();

    // Guard: block overselling unless the shop opted into it.
    if (!settings.allowSellWhenOutOfStock) {
      final shortItems = <String>[];
      for (final line in state) {
        if (line.isService) continue;
        final product = await productRepo.byId(line.productId);
        if (product != null && product.stockQty < line.quantity) {
          shortItems.add(line.name);
        }
      }
      if (shortItems.isNotEmpty) throw OutOfStockException(shortItems);
    }

    final sale = Sale()
      ..saleNumber = await saleRepo.nextSaleNumber()
      ..customerName = customerName
      ..items = state
          .map((l) => SaleItem()
            ..name = l.name
            ..quantity = l.quantity
            ..unitPrice = l.unitPrice
            ..unitCost = l.unitCost
            ..lineTotal = l.lineTotal
            ..productId = l.productId
            ..productUid = l.productUid)
          .toList()
      ..subtotal = total
      ..discount = 0
      ..total = total
      ..status = status
      ..paymentMethod = paymentMethod
      ..amountReceived = amountReceived
      ..notes = notes
      ..createdAt = date ?? DateTime.now();

    await saleRepo.save(sale);
    for (final line in state) {
      await productRepo.decrementStock(line.productId, line.quantity);
    }
    clear();
    return sale;
  }
}

final cartControllerProvider =
    NotifierProvider<CartController, List<CartLine>>(CartController.new);
