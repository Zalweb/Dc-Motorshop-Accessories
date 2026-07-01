import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/providers.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/product.dart';
import 'add_product_screen.dart';
import 'bulk_queue_item.dart';

/// How long to ignore detections after a scan before the next one is accepted.
const _scanCooldown = Duration(seconds: 4);

/// Continuous barcode scanner for Bulk Add. The camera stays open across scans;
/// each scan vibrates, shows a top banner with the product name, and updates the
/// running tally. Existing products are staged as restocks, unknown barcodes
/// prompt Add/Skip (and open the Add Product form inline). Pops with the
/// accumulated [BulkQueueItem] list.
class BulkScanScreen extends ConsumerStatefulWidget {
  const BulkScanScreen({super.key, this.initialItems = const []});

  /// Queue carried over from the Bulk Add page so repeat scans keep tallying.
  final List<BulkQueueItem> initialItems;

  @override
  ConsumerState<BulkScanScreen> createState() => _BulkScanScreenState();
}

class _BulkScanScreenState extends ConsumerState<BulkScanScreen> {
  late final List<BulkQueueItem> _items = [...widget.initialItems];
  final _controller = MobileScannerController();

  /// Total accepted scans this session — shown as "Scanned: N".
  int _scanned = 0;

  /// Gate that ignores frames while processing or during the scan cooldown.
  bool _busy = false;

  /// Name shown in the top banner after a scan; cleared by [_bannerTimer].
  String? _bannerName;
  Timer? _bannerTimer;

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_busy) return;
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value.isEmpty) return;
    _handle(value);
  }

  Future<void> _handle(String code) async {
    setState(() => _busy = true);

    final existing =
        await ref.read(productRepositoryProvider).findByBarcode(code);
    if (!mounted) return;

    // Already tallied this barcode this session → bump its quantity.
    final queued = _itemForBarcode(code);
    if (queued != null) {
      setState(() {
        queued.quantity += 1;
        _scanned += 1;
      });
      _notify(queued.name);
      _resumeSoon();
      return;
    }

    if (existing != null) {
      setState(() {
        _items.insert(0, BulkQueueItem.restock(existing));
        _scanned += 1;
      });
      _notify(existing.name);
      _resumeSoon();
      return;
    }

    // Unknown barcode → ask Add or Skip without leaving the camera.
    final shouldAdd = await _askAddOrSkip(code);
    if (!mounted) return;
    if (shouldAdd != true) {
      _resumeSoon();
      return;
    }

    final draft = await context.push<Product>(
      RoutePaths.addProduct,
      extra: AddProductArgs(initialBarcode: code, stage: true),
    );
    if (!mounted) return;
    if (draft != null) {
      setState(() {
        _items.insert(0, BulkQueueItem.newProduct(draft));
        _scanned += 1;
      });
      _notify(draft.name);
    }
    _resumeSoon();
  }

  BulkQueueItem? _itemForBarcode(String code) {
    for (final item in _items) {
      if (item.barcode == code) return item;
    }
    return null;
  }

  /// Vibrates and shows the scanned product's name in the top banner.
  void _notify(String name) {
    HapticFeedback.vibrate();
    _bannerTimer?.cancel();
    setState(() => _bannerName = name);
    _bannerTimer = Timer(_scanCooldown, () {
      if (mounted) setState(() => _bannerName = null);
    });
  }

  /// Holds the cooldown so the same in-view barcode isn't re-counted too soon.
  void _resumeSoon() {
    Future.delayed(_scanCooldown, () {
      if (mounted) setState(() => _busy = false);
    });
  }

  Future<bool?> _askAddOrSkip(String code) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New product'),
        content: Text(
          'No product matches barcode "$code". Add it as a new product?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_items);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan barcodes'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(_items),
              child: const Text('DONE'),
            ),
          ],
        ),
        body: Stack(
          alignment: Alignment.center,
          children: [
            MobileScanner(controller: _controller, onDetect: _onDetect),
            Container(
              width: 240,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            if (_bannerName != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _ScanBanner(name: _bannerName!),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ScanStatusBar(scanned: _scanned),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanBanner extends StatelessWidget {
  const _ScanBanner({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        color: AppColors.active.withValues(alpha: 0.95),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Scanned: $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanStatusBar extends StatelessWidget {
  const _ScanStatusBar({required this.scanned});

  final int scanned;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black.withValues(alpha: 0.6),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Point camera at barcode.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Scanned: $scanned',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
