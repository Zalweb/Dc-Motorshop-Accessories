import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product_web.dart';
import '../../core/utils/security_sanitizer.dart';
import '../../core/web/web_session.dart';

/// Web-safe, Supabase-backed product repository (cloud-only). Product here
/// resolves to the plain web model via the model barrel on web.
class ProductRepositoryWeb {
  ProductRepositoryWeb({required this.db});

  final SupabaseClient db;

  String get _bizId => WebSession.businessId ?? '';

  Future<String> _ensureBizId() async {
    if (_bizId.isNotEmpty) return _bizId;
    final id = await WebSession.ensureBusinessId(db);
    return id ?? '';
  }

  static const _tbl = 'products';

  Stream<List<Product>> watchAll() {
    final controller = StreamController<List<Product>>.broadcast();
    Future<void> emit() async {
      final rows = await _fetch();
      if (!controller.isClosed) controller.add(rows);
    }

    emit();
    final timer = Timer.periodic(const Duration(seconds: 15), (_) => emit());
    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };
    return controller.stream;
  }

  Future<List<Product>> all() => _fetch();

  Future<List<Product>> _fetch() async {
    final bizId = await _ensureBizId();
    if (bizId.isEmpty) return [];
    final res = await db
        .from(_tbl)
        .select()
        .eq('business_id', bizId)
        .isFilter('deleted_at', null);
    final rows = List<Map<String, dynamic>>.from(res as List);
    final products = rows.map(Product.fromJson).toList();

    // 1. Resolve relational product_variants if variants list is empty
    final needsVariants =
        products.where((p) => p.hasVariants && p.variants.isEmpty).toList();
    if (needsVariants.isNotEmpty) {
      try {
        final pids = needsVariants.map((p) => p.uid).toList();
        final vRes = await db
            .from('product_variants')
            .select()
            .inFilter('product_id', pids)
            .isFilter('deleted_at', null);
        final vRows = List<Map<String, dynamic>>.from(vRes as List);
        for (final p in needsVariants) {
          final pVariants = vRows
              .where((r) => r['product_id'] == p.uid)
              .map(ProductVariant.fromJson)
              .toList();
          if (pVariants.isNotEmpty) {
            p.variants = pVariants;
          }
        }
      } catch (_) {}
    }

    // 2. Resolve category names if stored as category_id UUID
    final categoryIds = products
        .map((p) => p.category)
        .where((c) => c != null && c.contains('-'))
        .toSet()
        .toList();
    if (categoryIds.isNotEmpty) {
      try {
        final catRes = await db
            .from('categories')
            .select('id, name')
            .inFilter('id', categoryIds);
        final catMap = {
          for (final c in catRes as List)
            (c as Map)['id']?.toString() ?? '': c['name']?.toString() ?? ''
        };
        for (final p in products) {
          if (p.category != null && catMap.containsKey(p.category)) {
            p.category = catMap[p.category];
          }
        }
      } catch (_) {}
    }

    // Sort newest-first (mirrors native sortByCreatedAtDesc).
    products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return products;
  }

  Future<Product?> byId(String id) async {
    final bizId = await _ensureBizId();
    if (bizId.isEmpty) return null;
    final res = await db
        .from(_tbl)
        .select()
        .eq('id', id)
        .eq('business_id', bizId)
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (res == null) return null;
    final product = Product.fromJson(Map<String, dynamic>.from(res as Map));
    if (product.hasVariants && product.variants.isEmpty) {
      try {
        final vRes = await db
            .from('product_variants')
            .select()
            .eq('product_id', product.uid)
            .isFilter('deleted_at', null);
        final vRows = List<Map<String, dynamic>>.from(vRes as List);
        if (vRows.isNotEmpty) {
          product.variants = vRows.map(ProductVariant.fromJson).toList();
        }
      } catch (_) {}
    }
    return product;
  }

  Future<Product?> findByBarcode(String code) async {
    final clean = sanitizePostgrestFilter(code);
    if (clean.isEmpty) return null;
    final bizId = await _ensureBizId();
    if (bizId.isEmpty) return null;
    final res = await db
        .from(_tbl)
        .select()
        .eq('business_id', bizId)
        .or('barcode.eq.$clean,part_number.eq.$clean')
        .isFilter('deleted_at', null)
        .limit(1)
        .maybeSingle();
    if (res != null) return Product.fromJson(Map<String, dynamic>.from(res as Map));

    // Search variants (barcode / sku / part_number)
    final vRes = await db
        .from('product_variants')
        .select('product_id')
        .eq('business_id', bizId)
        .or('barcode.eq.$clean,sku.eq.$clean,part_number.eq.$clean')
        .isFilter('deleted_at', null)
        .limit(1)
        .maybeSingle();
    if (vRes != null) {
      final pid = (vRes as Map)['product_id']?.toString();
      if (pid != null) return byId(pid);
    }
    return null;
  }

  Future<void> save(Product product) async {
    final bizId = await _ensureBizId();
    product
      ..updatedAt = DateTime.now()
      ..isDirty = true;
    final row = product.toJson()..['business_id'] = bizId;
    await db.from(_tbl).upsert(row, onConflict: 'id');

    if (product.hasVariants && product.variants.isNotEmpty) {
      try {
        final variantRows = product.variants.map((v) => {
          'id': v.uid,
          'product_id': product.uid,
          'business_id': bizId,
          'sku': v.sku,
          'barcode': v.barcode,
          'part_number': v.partNumber ?? product.partNumber,
          'variant_name': v.name,
          'option1_value': v.option1,
          'option2_value': v.option2,
          'cost_price': v.costPrice,
          'selling_price': v.sellingPrice,
          'stock_on_hand': v.stockQty,
          'reorder_level': v.reorderLevel,
          'is_active': v.isActive,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).toList();
        await db.from('product_variants').upsert(variantRows, onConflict: 'id');
      } catch (_) {}
    }
  }

  Future<void> delete(String id) async {
    await db.from(_tbl).update({'deleted_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id);
  }

  Future<void> decrementStock(String productId, int qty, {String? variantUid}) async {
    final product = await byId(productId);
    if (product == null || product.isService) return;
    if (product.hasVariants && variantUid != null) {
      final updated = <ProductVariant>[];
      for (final v in product.variants) {
        if (v.uid == variantUid) {
          v.stockQty = (v.stockQty - qty).clamp(0, 1 << 31);
          try {
            await db.from('product_variants').update({
              'stock_on_hand': v.stockQty,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            }).eq('id', v.uid);
          } catch (_) {}
        }
        updated.add(v);
      }
      product.variants = updated;
      product.stockQty = product.effectiveStockQty;
    } else {
      product.stockQty = (product.stockQty - qty).clamp(0, 1 << 31);
    }
    product
      ..updatedAt = DateTime.now()
      ..isDirty = true;
    await db
        .from(_tbl)
        .update({
          'stock_on_hand': product.stockQty,
          'variants': product.variants.map((v) => v.toJson()).toList(),
          'updated_at': product.updatedAt.toUtc().toIso8601String(),
        })
        .eq('id', productId);
  }
}
