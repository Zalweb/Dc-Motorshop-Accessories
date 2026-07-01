import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/category.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_container.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  Future<void> _addSheet(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    var isService = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('New category', style: AppTextStyles.headingMedium),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(hintText: 'Category name'),
                    ),
                    const SizedBox(height: 8),
                    GlassContainer(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      borderRadius: BorderRadius.circular(16),
                      child: SwitchListTile(
                        value: isService,
                        onChanged: (v) => setSheetState(() => isService = v),
                        title: Text('Service category', style: AppTextStyles.body),
                        subtitle: Text('Groups under the SERVICES filter',
                            style: AppTextStyles.bodySmall),
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          final name = controller.text.trim();
                          if (name.isNotEmpty) {
                            ref
                                .read(categoryRepositoryProvider)
                                .add(name, isService: isService);
                          }
                          Navigator.of(sheetContext).pop();
                        },
                        child: const Text('ADD CATEGORY'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addSheet(context, ref),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (categories) {
          if (categories.isEmpty) {
            return const EmptyState(
              icon: Icons.account_tree_outlined,
              title: 'No categories yet',
              body: 'Add a category to organize your products.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) =>
                _CategoryTile(category: categories[i], ref: ref),
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.ref});

  final Category category;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.account_tree_rounded, color: primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(category.name,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
          ),
          if (category.isService)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('SERVICE',
                  style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          IconButton(
            onPressed: () =>
                ref.read(categoryRepositoryProvider).delete(category.id),
            icon: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
