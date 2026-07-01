import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../models/product.dart';
import '../models/sale.dart';

/// Dev-only: populates a sample motorcycle catalog so screens have data to
/// show during testing. Triggered from the More screen.
Future<void> seedSampleData(WidgetRef ref) async {
  final categoryRepo = ref.read(categoryRepositoryProvider);
  final productRepo = ref.read(productRepositoryProvider);

  await categoryRepo.seed([
    'Engine Parts',
    'Brakes',
    'Electrical',
    'Tires & Wheels',
    'Lubricants/Oils',
    'Accessories',
    'Services',
  ]);

  final samples = <Product>[
    Product()
      ..name = 'NGK Spark Plug CPR8EA-9'
      ..category = 'Electrical'
      ..brand = 'NGK'
      ..barcode = '4961263000123'
      ..costPrice = 95
      ..sellingPrice = 150
      ..stockQty = 40
      ..unit = 'piece',
    Product()
      ..name = 'Brake Pad Set'
      ..category = 'Brakes'
      ..brand = 'Bendix'
      ..partNumber = 'BP-CLK125'
      ..costPrice = 220
      ..sellingPrice = 380
      ..stockQty = 18,
    Product()
      ..name = 'Engine Oil 10W-40 1L'
      ..category = 'Lubricants/Oils'
      ..brand = 'Motul'
      ..costPrice = 280
      ..sellingPrice = 420
      ..stockQty = 60
      ..unit = 'liter',
    Product()
      ..name = 'Tubeless Tire 90/80-17'
      ..category = 'Tires & Wheels'
      ..brand = 'Michelin'
      ..costPrice = 950
      ..sellingPrice = 1450
      ..stockQty = 12,
    Product()
      ..name = 'Change Oil (Labor)'
      ..category = 'Services'
      ..isService = true
      ..sellingPrice = 120,
  ];

  for (final product in samples) {
    await productRepo.save(product);
  }

  await _seedSampleSales(ref);
}

/// Adds a few sales spanning the payment statuses so the Sales History,
/// detail, and complete-payment flows have data to show. Skips if any sale
/// already exists so repeated taps don't pile up duplicates.
Future<void> _seedSampleSales(WidgetRef ref) async {
  final saleRepo = ref.read(saleRepositoryProvider);
  if ((await saleRepo.all()).isNotEmpty) return;

  final now = DateTime.now();

  SaleItem item(String name, int qty, double price, double cost) => SaleItem()
    ..name = name
    ..quantity = qty
    ..unitPrice = price
    ..unitCost = cost
    ..lineTotal = price * qty;

  final drafts = <Sale>[
    Sale()
      ..customerName = null
      ..items = [item('NGK Spark Plug CPR8EA-9', 2, 150, 95)]
      ..subtotal = 300
      ..total = 300
      ..status = 'paid'
      ..paymentMethod = 'cash'
      ..amountReceived = 300
      ..createdAt = now.subtract(const Duration(hours: 2)),
    Sale()
      ..customerName = 'Mang Tonyo'
      ..items = [item('Tubeless Tire 90/80-17', 1, 1450, 950)]
      ..subtotal = 1450
      ..total = 1450
      ..status = 'partial'
      ..paymentMethod = 'cash'
      ..amountReceived = 500
      ..createdAt = now.subtract(const Duration(days: 1, hours: 3)),
    Sale()
      ..customerName = 'Aling Nena'
      ..items = [item('Brake Pad Set', 1, 380, 220)]
      ..subtotal = 380
      ..total = 380
      ..status = 'unpaid'
      ..paymentMethod = 'cash'
      ..amountReceived = 0
      ..createdAt = now.subtract(const Duration(days: 4)),
    Sale()
      ..customerName = 'JR Auto Supply'
      ..items = [
        item('Engine Oil 10W-40 1L', 2, 420, 280),
        item('Change Oil (Labor)', 1, 120, 0),
      ]
      ..subtotal = 960
      ..total = 960
      ..status = 'paid'
      ..paymentMethod = 'gcash'
      ..amountReceived = 960
      ..createdAt = now.subtract(const Duration(days: 6, hours: 1)),
  ];

  for (var i = 0; i < drafts.length; i++) {
    drafts[i].saleNumber = await saleRepo.nextSaleNumber();
    await saleRepo.save(drafts[i]);
  }
}
