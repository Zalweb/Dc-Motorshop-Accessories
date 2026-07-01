import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/sale.dart';
import '../../shared/widgets/glass_container.dart';
import '../customers/customers_screen.dart';
import 'cart_controller.dart';

/// Slides the Current Order sheet up from the bottom. Resolves with the created
/// [Sale] when the user taps Create Sale, or null if dismissed.
Future<Sale?> showCartSheet(BuildContext context) {
  return showModalBottomSheet<Sale>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _CartSheet(),
  );
}

const _amountPresets = [50.0, 100.0, 200.0, 500.0];

class _CartSheet extends ConsumerStatefulWidget {
  const _CartSheet();

  @override
  ConsumerState<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends ConsumerState<_CartSheet> {
  final _customer = TextEditingController();
  final _customerFocus = FocusNode();
  final _notes = TextEditingController();
  final _amount = TextEditingController();
  final _changeGiven = TextEditingController();

  String _method = 'cash';
  DateTime? _customDate;
  bool _saving = false;

  // Status: default paid; auto-updates when amount is typed; user can also tap manually
  String _status = 'paid';
  double _change = 0;

  /// True once the user tries to save a credit sale without naming the customer.
  bool _customerError = false;

  @override
  void initState() {
    super.initState();
    _amount.addListener(_onAmountChanged);
    _customer.addListener(_onCustomerChanged);
  }

  void _onCustomerChanged() {
    if (!mounted) return;
    // Rebuild so the "already owes" hint tracks the typed name, and clear the
    // required-field error as soon as something is entered.
    setState(() {
      if (_customerError && _customer.text.trim().isNotEmpty) _customerError = false;
    });
  }

  bool get _requiresCustomer => _status != 'paid';

  void _onAmountChanged() {
    final total = ref.read(cartControllerProvider.notifier).total;
    final received = double.tryParse(_amount.text) ?? 0;
    // Only auto-update status when user has actually typed something
    if (_amount.text.trim().isNotEmpty) {
      setState(() {
        if (received <= 0) {
          _status = 'unpaid';
          _change = 0;
        } else if (received >= total) {
          _status = 'paid';
          _change = received - total;
        } else {
          _status = 'partial';
          _change = 0;
        }
      });
    } else {
      setState(() => _change = 0);
    }
  }

  @override
  void dispose() {
    _customer.dispose();
    _customerFocus.dispose();
    _notes.dispose();
    _amount.dispose();
    _changeGiven.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _customDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_customDate ?? now),
    );
    if (!mounted) return;
    setState(() {
      _customDate = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      );
    });
  }

  /// Combines the cashier's note with a "change still owed" line when partial
  /// change tracking is on and less than the full change was handed back.
  String? _composeNotes() {
    final base = _notes.text.trim();
    final trackChange =
        ref.read(businessSettingsStreamProvider).value?.trackPartialChange ??
            false;
    if (trackChange && _change > 0) {
      final given = double.tryParse(_changeGiven.text) ?? _change;
      final owed = _change - given;
      if (owed > 0.001) {
        final owedNote = 'Change still owed: ${formatPeso(owed)}';
        return base.isEmpty ? owedNote : '$base\n$owedNote';
      }
    }
    return base.isEmpty ? null : base;
  }

  Future<void> _createSale() async {
    if (_saving) return;

    // Always recompute the effective status from the actual amount received,
    // regardless of what the status buttons show.
    final total = ref.read(cartControllerProvider.notifier).total;
    final received = double.tryParse(_amount.text) ?? 0;
    final effectiveStatus = received <= 0
        ? 'unpaid'
        : received >= total
            ? 'paid'
            : 'partial';

    // Sync the status button to reflect the final computed status
    if (effectiveStatus != _status) {
      setState(() => _status = effectiveStatus);
    }

    // Credit sales must be tied to a customer so the balance lands on a ledger.
    if (effectiveStatus != 'paid' && _customer.text.trim().isEmpty) {
      setState(() => _customerError = true);
      _customerFocus.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a customer name for partial or unpaid sales.'),
        ),
      );
      return;
    }

    // Notify user if not fully paid
    if (effectiveStatus != 'paid') {
      final label =
          effectiveStatus == 'unpaid' ? 'Unpaid' : 'Partial payment';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('$label — proceed?'),
          content: Text(
            effectiveStatus == 'unpaid'
                ? 'No amount received. This sale will be recorded as Unpaid.'
                : 'Amount received is less than the total. This sale will be recorded as Partial payment.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Proceed'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _saving = true);
    final Sale sale;
    try {
      sale = await ref.read(cartControllerProvider.notifier).checkout(
            customerName:
                _customer.text.trim().isEmpty ? null : _customer.text.trim(),
            status: effectiveStatus,
            paymentMethod: _method,
            amountReceived: received,
            notes: _composeNotes(),
            date: _customDate,
          );
    } on OutOfStockException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Out of stock: ${e.items.join(', ')}. '
            'Enable "Allow selling when out of stock" in Inventory settings to override.',
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(sale);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = ref.watch(cartControllerProvider);
    final notifier = ref.read(cartControllerProvider.notifier);
    final total = notifier.total;
    final itemCount = cart.fold(0, (sum, l) => sum + l.quantity);

    // Resolve item thumbnails by product id.
    final products = ref.watch(productListStreamProvider).value ?? [];
    final imageById = {for (final p in products) p.id: p.imagePath};

    // Existing customers (for the dropdown) and the one matching the typed name.
    final existingCustomers =
        buildCustomerSummaries(ref.watch(saleListStreamProvider).value ?? []);
    final typedName = _customer.text.trim().toLowerCase();
    CustomerSummary? matchedCustomer;
    for (final c in existingCustomers) {
      if (c.name.toLowerCase() == typedName && typedName.isNotEmpty) {
        matchedCustomer = c;
        break;
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.92,
        child: Column(
          children: [
            _SheetHeader(itemCount: itemCount, total: total),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionLabel('Items'),
                      Text('${cart.length} total',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final line in cart)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CartItemCard(
                        name: line.name,
                        unitPrice: line.unitPrice,
                        quantity: line.quantity,
                        lineTotal: line.lineTotal,
                        imagePath: imageById[line.productId],
                        onAdd: () => notifier.increment(line.productId),
                        onRemove: () => notifier.decrement(line.productId),
                        onDelete: () => notifier.removeLine(line.productId),
                      ),
                    ),
                  const SizedBox(height: 8),
                  _SectionLabel(_requiresCustomer ? 'Customer (required)' : 'Customer'),
                  const SizedBox(height: 10),
                  _CustomerAutocomplete(
                    controller: _customer,
                    focusNode: _customerFocus,
                    customers: existingCustomers,
                    required: _requiresCustomer,
                    error: _customerError,
                  ),
                  if (matchedCustomer != null && matchedCustomer.outstanding > 0) ...[
                    const SizedBox(height: 10),
                    _OwesHint(customer: matchedCustomer),
                  ],
                  const SizedBox(height: 20),
                  _SectionLabel('Status'),
                  const SizedBox(height: 10),
                  _StatusRow(
                    value: _status,
                    onChanged: (v) => setState(() => _status = v),
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel('Payment method'),
                  const SizedBox(height: 10),
                  _MethodRow(
                    value: _method,
                    onChanged: (v) => setState(() => _method = v),
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel('Amount received'),
                  const SizedBox(height: 10),
                  _AmountPresets(
                    onPick: (v) {
                      _amount.text = v.toStringAsFixed(0);
                      _onAmountChanged();
                    },
                  ),
                  const SizedBox(height: 10),
                  _AmountField(controller: _amount),
                  const SizedBox(height: 8),
                  // Change display (when overpaid)
                  if (_change > 0)
                    _ChangeIndicator(change: _change),

                  // Partial change tracking: record change actually handed back.
                  if (_change > 0 &&
                      (ref
                              .watch(businessSettingsStreamProvider)
                              .value
                              ?.trackPartialChange ??
                          false)) ...[
                    const SizedBox(height: 12),
                    _SectionLabel('Change given'),
                    const SizedBox(height: 10),
                    _ChangeGivenField(
                      controller: _changeGiven,
                      fullChange: _change,
                      onChanged: () => setState(() {}),
                    ),
                  ],

                  const SizedBox(height: 20),
                  _SectionLabel('Notes'),
                  const SizedBox(height: 10),
                  _Field(controller: _notes, hint: 'Add a note...'),
                  const SizedBox(height: 16),
                  _DateButton(date: _customDate, onTap: _pickDateTime),
                  const SizedBox(height: 16),
                  _TotalCard(total: total),
                ],
              ),
            ),
            _SheetFooter(
              total: total,
              itemCount: itemCount,
              enabled: cart.isNotEmpty && !_saving,
              saving: _saving,
              onClear: cart.isEmpty ? null : notifier.clear,
              onCreate: _createSale,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.itemCount, required this.total});

  final int itemCount;
  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Order',
                  style: AppTextStyles.headingMedium.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$itemCount items  •  ${formatPeso(total)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.imagePath,
    required this.onAdd,
    required this.onRemove,
    required this.onDelete,
  });

  final String name;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  final String? imagePath;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(imagePath: imagePath, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${formatPeso(unitPrice)} each',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: AppColors.danger,
                tooltip: 'Remove',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stepper(quantity: quantity, onAdd: onAdd, onRemove: onRemove),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('SUBTOTAL',
                      style: AppTextStyles.labelCaps.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(formatPeso(lineTotal),
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper(
      {required this.quantity, required this.onAdd, required this.onRemove});

  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        _RoundBtn(icon: Icons.remove, color: primary, onTap: onRemove),
        SizedBox(
          width: 36,
          child: Text('$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
        ),
        _RoundBtn(icon: Icons.add, color: primary, onTap: onAdd),
      ],
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn(
      {required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.imagePath, this.size = 44});

  final String? imagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (imagePath != null && File(imagePath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(File(imagePath!),
            width: size, height: size, fit: BoxFit.cover),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.inventory_2_outlined,
          color: theme.colorScheme.onSurfaceVariant, size: size * 0.5),
    );
  }
}


class _MethodRow extends StatelessWidget {
  const _MethodRow({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  static const _methods = [
    ('cash', 'Cash', Icons.payments_outlined),
    ('gcash', 'GCash', Icons.smartphone_outlined),
    ('bank', 'Bank', Icons.account_balance_outlined),
    ('card', 'Card', Icons.credit_card_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Row(
      children: [
        for (final (id, label, icon) in _methods)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: id == 'card' ? 0 : 10),
              child: InkWell(
                onTap: () => onChanged(id),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: value == id
                        ? primary
                        : theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: value == id
                          ? primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(icon,
                          size: 20,
                          color: value == id
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 6),
                      Text(label,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: value == id
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AmountPresets extends StatelessWidget {
  const _AmountPresets({required this.onPick});

  final ValueChanged<double> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _amountPresets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final value = _amountPresets[i];
          return InkWell(
            onTap: () => onPick(value),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Text(formatPeso(value),
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          );
        },
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      style: AppTextStyles.headingMedium,
      decoration: const InputDecoration(prefixText: '₱  ', hintText: '0.00'),
    );
  }
}

class _ChangeGivenField extends StatelessWidget {
  const _ChangeGivenField({
    required this.controller,
    required this.fullChange,
    required this.onChanged,
  });

  final TextEditingController controller;
  final double fullChange;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final given = double.tryParse(controller.text) ?? fullChange;
    final owed = (fullChange - given).clamp(0, fullChange);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            prefixText: '₱  ',
            hintText: fullChange.toStringAsFixed(2),
          ),
        ),
        if (owed > 0.001) ...[
          const SizedBox(height: 8),
          Text(
            'Still owed to customer: ${formatPeso(owed.toDouble())}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
          ),
        ],
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(hintText: hint),
    );
  }
}

/// Customer name field with a dropdown of existing customers. Picking one links
/// the sale to that ledger so a credit balance adds to what they already owe.
class _CustomerAutocomplete extends StatelessWidget {
  const _CustomerAutocomplete({
    required this.controller,
    required this.focusNode,
    required this.customers,
    required this.required,
    required this.error,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<CustomerSummary> customers;
  final bool required;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<CustomerSummary>(
      textEditingController: controller,
      focusNode: focusNode,
      displayStringForOption: (c) => c.name,
      optionsBuilder: (value) {
        final q = value.text.trim().toLowerCase();
        if (q.isEmpty) return customers;
        return customers.where((c) => c.name.toLowerCase().contains(q));
      },
      fieldViewBuilder: (context, textController, node, onSubmit) {
        return TextField(
          controller: textController,
          focusNode: node,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => onSubmit(),
          decoration: InputDecoration(
            hintText: required ? 'Customer name (required)' : 'Customer name (optional)',
            prefixIcon: const Icon(Icons.person_add_alt_1),
            errorText: error ? 'Required for partial or unpaid sales' : null,
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final theme = Theme.of(context);
        final width = MediaQuery.of(context).size.width - 40;
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.surfaceContainerHigh,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 240, maxWidth: width),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final c = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                      child: Text(
                        c.initials.isEmpty ? '?' : c.initials,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    title: Text(c.name, style: AppTextStyles.body),
                    trailing: c.outstanding > 0
                        ? Text(
                            'owes ${formatPeso(c.outstanding)}',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
                          )
                        : null,
                    onTap: () => onSelected(c),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Inline reminder that the chosen customer already carries a balance, which
/// the new credit sale will be added to.
class _OwesHint extends StatelessWidget {
  const _OwesHint({required this.customer});

  final CustomerSummary customer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${customer.name} already owes ${formatPeso(customer.outstanding)}. '
              'A balance on this sale adds to their total.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.date, required this.onTap});

  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = date == null
        ? 'Set custom date & time'
        : DateFormat('MMM d, yyyy · h:mm a').format(date!);
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.schedule),
      label: Text(label),
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
          Text(formatPeso(total), style: AppTextStyles.headingLarge),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.labelCaps
          .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

class _SheetFooter extends StatelessWidget {
  const _SheetFooter({
    required this.total,
    required this.itemCount,
    required this.enabled,
    required this.saving,
    required this.onClear,
    required this.onCreate,
  });

  final double total;
  final int itemCount;
  final bool enabled;
  final bool saving;
  final VoidCallback? onClear;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ORDER TOTAL',
                        style: AppTextStyles.labelCaps.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    Text('$itemCount items',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                Text(formatPeso(total), style: AppTextStyles.headingLarge),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ClearButton(onTap: onClear),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: enabled ? onCreate : null,
                    icon: saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2.4))
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('CREATE SALE'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
    );
  }
}


// ─── Change indicator ─────────────────────────────────────────────────────────
class _ChangeIndicator extends StatelessWidget {
  const _ChangeIndicator({required this.change});
  final double change;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.savings_outlined, color: Color(0xFF22C55E), size: 18),
          const SizedBox(width: 10),
          Text(
            'Change:  ${formatPeso(change)}',
            style: const TextStyle(
              color: Color(0xFF22C55E),
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}


// ─── Status row ───────────────────────────────────────────────────────────────
class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SegBtn(
            label: 'Paid',
            icon: Icons.check_circle_outline,
            selected: value == 'paid',
            color: const Color(0xFF22C55E),
            onTap: () => onChanged('paid'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SegBtn(
            label: 'Partial',
            icon: Icons.adjust,
            selected: value == 'partial',
            color: const Color(0xFFF59E0B),
            onTap: () => onChanged('partial'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SegBtn(
            label: 'Unpaid',
            icon: Icons.cancel_outlined,
            selected: value == 'unpaid',
            color: const Color(0xFFEF4444),
            onTap: () => onChanged('unpaid'),
          ),
        ),
      ],
    );
  }
}

class _SegBtn extends StatelessWidget {
  const _SegBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = selected ? color : theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : theme.colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: fg, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
