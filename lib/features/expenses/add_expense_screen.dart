import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/expense.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({
    super.key,
    required this.initialType,
    this.expense,
  });

  final String initialType;
  final Expense? expense;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  late String _type;

  // Amount
  final _amountCtrl = TextEditingController();

  // Variable Expense specific
  String _varCategory = 'other';
  DateTime _transactionDate = DateTime.now();
  final _varDescCtrl = TextEditingController();
  final _varNotesCtrl = TextEditingController();
  bool _includeInCalculations = true;

  // Fixed Expense specific
  final _fixedNameCtrl = TextEditingController();
  String _fixedCategory = 'rent';
  String _fixedFrequency = 'monthly';
  DateTime _fixedStartDate = DateTime.now();
  DateTime? _fixedEndDate;
  final _fixedDescCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _type = widget.expense?.type ?? widget.initialType;
    if (widget.expense != null) {
      final exp = widget.expense!;
      _amountCtrl.text = exp.amount == 0 ? '' : exp.amount.toStringAsFixed(2);
      if (_type == 'variable') {
        _varCategory = exp.category ?? 'other';
        _transactionDate = exp.createdAt;
        _varDescCtrl.text = exp.label;
        _varNotesCtrl.text = exp.note ?? '';
        _includeInCalculations = exp.includeInCalculations;
      } else {
        _fixedNameCtrl.text = exp.label;
        _fixedCategory = exp.category ?? 'rent';
        _fixedFrequency = exp.frequency ?? 'monthly';
        _fixedStartDate = exp.createdAt;
        _fixedEndDate = exp.endDate;
        _fixedDescCtrl.text = exp.note ?? '';
      }
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _varDescCtrl.dispose();
    _varNotesCtrl.dispose();
    _fixedNameCtrl.dispose();
    _fixedDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, DateTime initial, ValueChanged<DateTime> onSelected) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final expense = widget.expense ?? Expense();
    expense.type = _type;
    expense.amount = amount;

    if (_type == 'variable') {
      if (_varDescCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a description')),
        );
        return;
      }
      expense.label = _varDescCtrl.text.trim();
      expense.category = _varCategory;
      expense.createdAt = _transactionDate;
      expense.note = _varNotesCtrl.text.trim().isEmpty ? null : _varNotesCtrl.text.trim();
      expense.includeInCalculations = _includeInCalculations;
    } else {
      if (_fixedNameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a name')),
        );
        return;
      }
      expense.label = _fixedNameCtrl.text.trim();
      expense.category = _fixedCategory;
      expense.frequency = _fixedFrequency;
      expense.createdAt = _fixedStartDate;
      expense.endDate = _fixedEndDate;
      expense.note = _fixedDescCtrl.text.trim().isEmpty ? null : _fixedDescCtrl.text.trim();
      expense.includeInCalculations = true; // fixed are always included
    }

    await ref.read(expenseRepositoryProvider).save(expense);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF4ADE80).withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF4ADE80)
                : (isDark ? AppColors.border : AppColors.borderLight),
            width: 1.5,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: selected
                ? const Color(0xFF4ADE80)
                : (isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDateCard({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = date != null ? DateFormat('MMM d, yyyy').format(date) : 'No end date';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgSurface : AppColors.bgSurfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.border : AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4ADE80).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFF4ADE80),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgSurface2 : AppColors.bgSurface2Light,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                dateStr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateButton(String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgSurface : AppColors.bgSurfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.border : AppColors.borderLight),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AMOUNT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgSurface : AppColors.bgSurfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.border : AppColors.borderLight),
          ),
          child: TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              prefixText: '₱ ',
              prefixStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              ),
              hintText: '0.00',
              hintStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgSurface : AppColors.bgSurfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.border : AppColors.borderLight),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
                fontSize: 16,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: maxLines > 1 ? 12 : 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSurface : AppColors.bgSurfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.border : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF4ADE80),
          ),
        ],
      ),
    );
  }

  Widget _buildVariableForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = ['electricity', 'water', 'supplies', 'maintenance', 'transportation', 'other'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAmountInput(),
        const SizedBox(height: 24),
        Text(
          'CATEGORY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: categories.map((cat) {
            return _buildChip(
              label: cat,
              selected: _varCategory == cat,
              onTap: () => setState(() => _varCategory = cat),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          'TRANSACTION DATE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildDateCard(
          label: 'Transaction Date',
          date: _transactionDate,
          onTap: () => _selectDate(context, _transactionDate, (d) => setState(() => _transactionDate = d)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildQuickDateButton('Today', () => setState(() => _transactionDate = DateTime.now())),
            const SizedBox(width: 8),
            _buildQuickDateButton(
              'Yesterday',
              () => setState(() => _transactionDate = DateTime.now().subtract(const Duration(days: 1))),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildTextField(
          label: 'Description',
          hint: 'What is this expense for?',
          controller: _varDescCtrl,
        ),
        const SizedBox(height: 24),
        _buildTextField(
          label: 'Notes (Optional)',
          hint: 'Additional notes',
          controller: _varNotesCtrl,
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        _buildSwitchRow(
          title: 'Include in calculations',
          subtitle: 'Count this toward expense averages',
          value: _includeInCalculations,
          onChanged: (val) => setState(() => _includeInCalculations = val),
        ),
      ],
    );
  }

  Widget _buildFixedForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = ['rent', 'utilities', 'salaries', 'other'];
    final frequencies = ['daily', 'monthly', 'quarterly', 'yearly'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: 'Name',
          hint: 'e.g. Shop rent',
          controller: _fixedNameCtrl,
        ),
        const SizedBox(height: 24),
        _buildAmountInput(),
        const SizedBox(height: 24),
        Text(
          'CATEGORY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: categories.map((cat) {
            return _buildChip(
              label: cat,
              selected: _fixedCategory == cat,
              onTap: () => setState(() => _fixedCategory = cat),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          'FREQUENCY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: frequencies.map((freq) {
            return _buildChip(
              label: freq,
              selected: _fixedFrequency == freq,
              onTap: () => setState(() => _fixedFrequency = freq),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          'START DATE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildDateCard(
          label: 'Start Date',
          date: _fixedStartDate,
          onTap: () => _selectDate(context, _fixedStartDate, (d) => setState(() => _fixedStartDate = d)),
        ),
        const SizedBox(height: 24),
        Text(
          'END DATE (OPTIONAL)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildDateCard(
          label: 'End Date',
          date: _fixedEndDate,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _fixedEndDate ?? DateTime.now(),
              firstDate: DateTime(DateTime.now().year - 5),
              lastDate: DateTime(DateTime.now().year + 5),
            );
            if (picked != null) {
              setState(() => _fixedEndDate = picked);
            }
          },
        ),
        if (_fixedEndDate != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              _buildQuickDateButton('Clear End Date', () => setState(() => _fixedEndDate = null)),
            ],
          ),
        ],
        const SizedBox(height: 24),
        _buildTextField(
          label: 'Description (Optional)',
          hint: 'Notes about this expense',
          controller: _fixedDescCtrl,
          maxLines: 3,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgBase : AppColors.bgBaseLight,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDark ? AppColors.bgBase : AppColors.bgBaseLight,
        elevation: 0,
        title: Text(
          widget.expense != null
              ? (_type == 'variable' ? 'Edit Variable Expense' : 'Edit Fixed Expense')
              : (_type == 'variable' ? 'New Variable Expense' : 'New Fixed Expense'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _type == 'variable' ? _buildVariableForm() : _buildFixedForm(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4ADE80),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.expense != null ? 'Update Expense' : 'Save Expense',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
