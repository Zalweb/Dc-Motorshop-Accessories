import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/business_settings.dart';
import '../data/models/category.dart';
import '../data/models/expense.dart';
import '../data/models/product.dart';
import '../data/models/sale.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/maintenance_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/sale_repository.dart';
import '../data/repositories/settings_repository.dart';
import 'db/isar_service.dart';
import 'supabase/supabase_providers.dart';

/// Bound in main() after Isar opens. Repositories read the Isar instance here.
final isarServiceProvider = Provider<IsarService>(
  (ref) => throw UnimplementedError('isarServiceProvider must be overridden'),
);

/// Bound in main() after SharedPreferences loads.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

/// Reactive provider for calendar closed dates.
class CalendarClosedDatesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    return ref.watch(sharedPreferencesProvider).getStringList('calendar_closed_dates') ?? [];
  }

  void set(List<String> dates) {
    state = dates;
  }
}

final calendarClosedDatesProvider = NotifierProvider<CalendarClosedDatesNotifier, List<String>>(
  CalendarClosedDatesNotifier.new,
);

/// Convenience accessor for the open Isar instance.
final isarProvider = Provider<Isar>(
  (ref) => ref.watch(isarServiceProvider).isar,
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(isarProvider),
    ref.watch(sharedPreferencesProvider),
    ref.watch(supabaseAuthServiceProvider),
  ),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(isarProvider)),
);

/// Live business settings; emits on every change (onboarding, checklist).
final businessSettingsStreamProvider = StreamProvider<BusinessSettings?>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(ref.watch(isarProvider)),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(isarProvider)),
);

final saleRepositoryProvider = Provider<SaleRepository>(
  (ref) => SaleRepository(ref.watch(isarProvider)),
);

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepository(ref.watch(isarProvider)),
);

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>(
  (ref) => MaintenanceRepository(ref.watch(isarProvider)),
);

final productListStreamProvider = StreamProvider<List<Product>>(
  (ref) => ref.watch(productRepositoryProvider).watchAll(),
);

final categoryListStreamProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);

final saleListStreamProvider = StreamProvider<List<Sale>>(
  (ref) => ref.watch(saleRepositoryProvider).watchAll(),
);

final expenseListStreamProvider = StreamProvider<List<Expense>>(
  (ref) => ref.watch(expenseRepositoryProvider).watchAll(),
);
