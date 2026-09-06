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

  static List<Product>? _cachedProducts;
  static final List<StreamController<List<Product>>> _controllers = [];
  static Timer? _pollTimer;
  static bool _isFetching = false;

  static void clearCache() {
    _cachedProducts = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _isFetching = false;
  }

  static void _notifyControllers() {
    if (_cachedProducts == null) return;
    final snapshot = List<Product>.unmodifiable(_cachedProducts!);
    for (final c in List.of(_controllers)) {
      if (!c.isClosed) c.add(snapshot);
    }
  }

  static bool _productsEqual(List<Product>? a, List<Product> b) {
    if (a == null) return false;
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      final pA = a[i];
      final pB = b[i];
      if (pA.uid != pB.uid ||
          pA.stockQty != pB.stockQty ||
          pA.sellingPrice != pB.sellingPrice ||
          pA.name != pB.name ||
          pA.category != pB.category ||
          pA.updatedAt != pB.updatedAt ||
          pA.variants.length != pB.variants.length) {
        return false;
      }
    }
    return true;
  }

  Stream<List<Product>> watchAll() {
    final controller = StreamController<List<Product>>.broadcast();
    _controllers.add(controller);

    // 1. Immediately emit cached data if available for instant tab rendering
    if (_cachedProducts != null) {
      controller.add(List<Product>.unmodifiable(_cachedProducts!));
    }

    Future<void> syncFromCloud() async {
      if (_isFetching) return;
      _isFetching = true;
      try {
        final rows = await _fetch();
        if (!_productsEqual(_cachedProducts, rows)) {
          _cachedProducts = rows;
          _notifyControllers();
        }
      } catch (_) {
        // Retain existing cache on network glitch
      } finally {
        _isFetching = false;
      }
    }

    // Trigger initial fetch
    syncFromCloud();

    // Deduplicated shared polling timer (30s)
    _pollTimer ??= Timer.periodic(const Duration(seconds: 30), (_) => syncFromCloud());

    controller.onCancel = () {
      _controllers.remove(controller);
      controller.close();
      if (_controllers.isEmpty) {
        _pollTimer?.cancel();
        _pollTimer = null;
      }
    };
    return controller.stream;
  }

  Future<List<Product>> all() async {
    final bizId = await _ensureBizId();
    if (bizId.isEmpty) return [];
    if (_cachedProducts != null) {
      return List<Product>.unmodifiable(_cachedProducts!);
    }
    final rows = await _fetch();
    _cachedProducts = rows;
    return rows;
  }

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
    if (_cachedProducts != null) {
      final cached = _cachedProducts!.cast<Product?>().firstWhere(
        (p) => p?.uid == id || p?.id.toString() == id,
        orElse: () => null,
      );
      if (cached != null) return cached;
    }

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

    if (_cachedProducts != null) {
      final match = _cachedProducts!.cast<Product?>().firstWhere(
        (p) {
          if (p == null) return false;
          if (p.barcode == clean || p.partNumber == clean) return true;
          if (p.hasVariants) {
            for (final v in p.variants) {
              if (v.barcode == clean || v.sku == clean || v.partNumber == clean) {
                return true;
              }
            }
          }
          return false;
        },
        orElse: () => null,
      );
      if (match != null) return match;
    }

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
    row.remove('image_path');
    row.remove('stock_qty');

    if (_cachedProducts != null) {
      final list = List<Product>.from(_cachedProducts!);
      final idx = list.indexWhere((p) => p.uid == product.uid || (p.id != 0 && p.id == product.id));
      if (idx != -1) {
        list[idx] = product;
      } else {
        list.insert(0, product);
      }
      _cachedProducts = list;
      _notifyControllers();
    }

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
    if (_cachedProducts != null) {
      final list = List<Product>.from(_cachedProducts!);
      list.removeWhere((p) => p.uid == id || p.id.toString() == id);
      _cachedProducts = list;
      _notifyControllers();
    }
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

    if (_cachedProducts != null) {
      final list = List<Product>.from(_cachedProducts!);
      final idx = list.indexWhere((p) => p.uid == productId || p.id.toString() == productId);
      if (idx != -1) {
        list[idx] = product;
        _cachedProducts = list;
        _notifyControllers();
      }
    }

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
