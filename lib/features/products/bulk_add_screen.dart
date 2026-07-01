import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/product.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_container.dart';
import 'add_product_screen.dart';
import 'bulk_queue_item.dart';
import 'bulk_scan_screen.dart';

class BulkAddScreen extends ConsumerStatefulWidget {
  const BulkAddScreen({super.key});

  @override
  ConsumerState<BulkAddScreen> createState() => _BulkAddScreenState();
}

class _BulkAddScreenState extends ConsumerState<BulkAddScreen> {
  final _input = TextEditingController();
  final List<BulkQueueItem> _queue = [];
  bool _saving = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  /// Opens the continuous scanner; it returns the accumulated queue (which may
  /// include items added during the session), replacing the current one.
  Future<void> _scan() async {
    final result = await Navigator.of(context).push<List<BulkQueueItem>>(
      MaterialPageRoute(
        builder: (_) => BulkScanScreen(initialItems: _queue),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _queue
        ..clear()
        ..addAll(result);
    });
  }

  void _submitBarcode() {
    final code = _input.text;
    _input.clear();
    _addBarcode(code);
  }

  /// Opens the Add Product form (staged), then queues the returned draft.
  void _addViaForm() {
    final code = _input.text.trim();
    _input.clear();
    _openForm(initialBarcode: code.isEmpty ? null : code);
  }

  Future<void> _openForm({String? initialBarcode}) async {
    final draft = await context.push<Product>(
      RoutePaths.addProduct,
      extra: AddProductArgs(initialBarcode: initialBarcode, stage: true),
    );
    if (!mounted || draft == null) return;
    setState(() => _queue.insert(0, BulkQueueItem.newProduct(draft)));
  }

  /// Stages a typed barcode: an existing product becomes a restock entry (or
  /// bumps a matching one); an unknown barcode opens the Add Product form.
  Future<void> _addBarcode(String raw) async {
    final code = raw.trim();
    if (code.isEmpty) return;

    final existing =
        await ref.read(productRepositoryProvider).findByBarcode(code);
    if (!mounted) return;

    final queued = _itemForBarcode(code);
    if (queued != null) {
      setState(() => queued.quantity += 1);
      return;
    }
    if (existing != null) {
      setState(() => _queue.insert(0, BulkQueueItem.restock(existing)));
      return;
    }
    await _openForm(initialBarcode: code);
  }

  BulkQueueItem? _itemForBarcode(String barcode) {
    for (final item in _queue) {
      if (item.barcode == barcode) return item;
    }
    return null;
  }

  void _remove(BulkQueueItem item) => setState(() => _queue.remove(item));

  void _changeQty(BulkQueueItem item, int delta) {
    setState(() => item.quantity = item.quantity + delta);
  }

  /// Commits every queued item in one pass, then returns to the caller.
  Future<void> _confirm() async {
    if (_queue.isEmpty || _saving) return;
    setState(() => _saving = true);

    final repo = ref.read(productRepositoryProvider);
    for (final item in _queue) {
      if (item.isRestock) {
        item.existing!.stockQty += item.restockQty;
        await repo.save(item.existing!);
      } else {
        await repo.save(item.draft!);
      }
    }

    final count = _queue.length;
    if (!mounted) return;
    _snack('Added $count ${count == 1 ? 'product' : 'products'}');
    context.pop();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Add Products')),
      bottomNavigationBar: _queue.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton(
                  onPressed: _saving ? null : _confirm,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: _saving
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : Text(
                          'ADD ${_queue.length} '
                          '${_queue.length == 1 ? 'PRODUCT' : 'PRODUCTS'}',
                        ),
                ),
              ),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: _scan,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('SCAN BARCODES'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        decoration: const InputDecoration(
                          hintText: 'Enter barcode or add without barcode',
                        ),
                        onSubmitted: (_) => _submitBarcode(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(72, 56),
                      ),
                      onPressed: _addViaForm,
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          Expanded(
            child: _queue.isEmpty
                ? const EmptyState(
                    icon: Icons.crop_free,
                    title: 'No products in queue',
                    body: 'Scan barcodes or tap Add to build your queue, then '
                        'confirm to save them all at once.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: _queue.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _QueueTile(
                      item: _queue[i],
                      onChangeQty: (delta) => _changeQty(_queue[i], delta),
                      onRemove: () => _remove(_queue[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({
    required this.item,
    required this.onChangeQty,
    required this.onRemove,
  });

  final BulkQueueItem item;
  final ValueChanged<int> onChangeQty;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRestock = item.isRestock;

    final subtitle = isRestock
        ? '+${item.restockQty} · now '
            '${item.existing!.stockQty + item.restockQty} in stock'
        : item.canEditQuantity
            ? 'New product · stock ${item.draft!.stockQty}'
            : 'New service';
    final (icon, color) = isRestock
        ? (Icons.check_circle_rounded, AppColors.active)
        : (Icons.add_circle_rounded, theme.colorScheme.primary);

    return GlassContainer(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (item.canEditQuantity)
            _QtyStepper(quantity: item.quantity, onChange: onChangeQty),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
            color: theme.colorScheme.onSurfaceVariant,
            tooltip: 'Remove from queue',
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({required this.quantity, required this.onChange});

  final int quantity;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: quantity > 1 ? () => onChange(-1) : null,
          icon: const Icon(Icons.remove_circle_outline_rounded),
          visualDensity: VisualDensity.compact,
          tooltip: 'Decrease',
        ),
        SizedBox(
          width: 24,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        IconButton(
          onPressed: () => onChange(1),
          icon: const Icon(Icons.add_circle_outline_rounded),
          visualDensity: VisualDensity.compact,
          tooltip: 'Increase',
        ),
      ],
    );
  }
}
