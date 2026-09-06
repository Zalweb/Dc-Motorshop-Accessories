import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/business_settings_web.dart' as web_models;
import '../data/models/category_web.dart';
import '../data/models/expense_web.dart';
import '../data/models/inventory_transaction_web.dart';
import '../data/models/product_web.dart';
import '../data/models/sale_web.dart';
import '../data/repositories/auth_repository_web.dart';
import '../data/repositories/category_repository_web.dart';
import '../data/repositories/expense_repository_web.dart';
import '../data/repositories/inventory_repository_web.dart';
import '../data/repositories/maintenance_repository_web.dart';
import '../data/repositories/product_repository_web.dart';
import '../data/repositories/sale_repository_web.dart';
import '../data/repositories/settings_repository_web.dart';
import 'supabase/supabase_providers_web.dart';
import 'supabase/supabase_service.dart';
import 'update/app_update_controller.dart';
import 'update/app_update_info.dart';
import 'update/app_update_service.dart';

/// Bound in main() after SharedPreferences loads.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

SupabaseClient get _db => SupabaseService.client;

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

final authRepositoryProvider = Provider<AuthRepositoryWeb>(
  (ref) => AuthRepositoryWeb(ref.watch(supabaseAuthServiceProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepositoryWeb>(
  (ref) => SettingsRepositoryWeb(db: _db),
);

final businessSettingsStreamProvider = StreamProvider<web_models.BusinessSettings?>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

final productRepositoryProvider = Provider<ProductRepositoryWeb>(
  (ref) => ProductRepositoryWeb(db: _db),
);

final categoryRepositoryProvider = Provider<CategoryRepositoryWeb>(
  (ref) => CategoryRepositoryWeb(db: _db),
);

final saleRepositoryProvider = Provider<SaleRepositoryWeb>(
  (ref) => SaleRepositoryWeb(db: _db),
);

final expenseRepositoryProvider = Provider<ExpenseRepositoryWeb>(
  (ref) => ExpenseRepositoryWeb(db: _db),
);

final inventoryRepositoryProvider = Provider<InventoryRepositoryWeb>(
  (ref) => InventoryRepositoryWeb(db: _db),
);

final maintenanceRepositoryProvider = Provider<MaintenanceRepositoryWeb>(
  (ref) => const MaintenanceRepositoryWeb(),
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

final recentInventoryTransactionsStreamProvider =
    StreamProvider<List<InventoryTransaction>>(
  (ref) => ref.watch(inventoryRepositoryProvider).watchRecent(),
);

final appUpdateServiceProvider = Provider<AppUpdateService>(
  (ref) => AppUpdateService(),
);

final appUpdateControllerProvider =
    AsyncNotifierProvider<AppUpdateNotifier, AppUpdateInfo?>(
  AppUpdateNotifier.new,
);
