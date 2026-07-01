import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/expense.dart';
import '../../shared/widgets/empty_state.dart';
import 'add_expense_screen.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addExpense(BuildContext context) async {
    final currentType = _tabController.index == 0 ? 'variable' : 'fixed';
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(initialType: currentType),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expenseListStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Variable'),
            Tab(text: 'Fixed'),
          ],
        ),
      ),
      body: expensesAsync.when(
        data: (expenses) {
          final variable = expenses.where((e) => e.type == 'variable').toList();
          final fixed = expenses.where((e) => e.type == 'fixed').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _ExpenseList(expenses: variable, type: 'Variable'),
              _ExpenseList(expenses: fixed, type: 'Fixed'),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addExpense(context),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

class _ExpenseList extends ConsumerWidget {
  const _ExpenseList({required this.expenses, required this.type});
  final List<Expense> expenses;
  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (expenses.isEmpty) {
      return EmptyState(
        icon: Icons.payments_outlined,
        title: 'No $type Expenses',
        body: 'Tap + to record your first one.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Padding for FAB
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final exp = expenses[index];
        return ListTile(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddExpenseScreen(
                  initialType: exp.type,
                  expense: exp,
                ),
                fullscreenDialog: true,
              ),
            );
          },
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(
            exp.label,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(DateFormat('MMM d, yyyy').format(exp.createdAt)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatPeso(exp.amount),
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                size: 20,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Theme.of(context).colorScheme.error,
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Expense?'),
                      content: Text('Are you sure you want to delete "${exp.label}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(expenseRepositoryProvider).delete(exp.id);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
